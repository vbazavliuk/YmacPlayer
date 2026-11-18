import Foundation

// MARK: - JavaScript Injection Helpers

/// Provides JavaScript scripts to be injected into the WKWebView for synchronizing YouTube Music player state with Ymac Player.
enum YTMJavaScript {

    /// Injection script that monitors playback state, queue, playlists, and user authentication, posting structured updates to the native handler.
    static let syncScript = #"""
    (() => {
        if (window.__ymacSyncInitialized) return;
        window.__ymacSyncInitialized = true;

        window.hasTriggeredGuide = Boolean(window.hasTriggeredGuide);
        window.hasAutoPausedInitial = Boolean(window.hasAutoPausedInitial);
        window.isSystemSleeping = Boolean(window.isSystemSleeping);
        window.setUserWantsPlayback = function(val) {
            window.userWantsPlayback = !!val;
            try {
                sessionStorage.setItem('__ymacUserWantsPlayback', val ? 'true' : 'false');
            } catch (e) {}
        };
        let persistedWants = false;
        try {
            const storedWants = sessionStorage.getItem('__ymacUserWantsPlayback');
            if (storedWants === 'true') {
                persistedWants = true;
            } else if (storedWants === null && window.location.href.includes('watch?')) {
                persistedWants = true;
            }
        } catch (e) {}
        window.userWantsPlayback = Boolean(window.userWantsPlayback || persistedWants);
        window.lastAttachedVideo = null;
        window.lastFullSyncTime = 0;
        window.__lastTimeUpdateSync = 0;

        window.setPlaybackIntent = function(wantsPlayback) {
            window.setUserWantsPlayback(wantsPlayback);
            const v = document.querySelector('video');
            const playBtn = document.querySelector(
                'ytmusic-player-bar #play-pause-button button, ' +
                'ytmusic-player-bar #play-pause-button, ' +
                'ytmusic-miniplayer .ytmusicPlayerControlsPlayPauseButton button, ' +
                'ytmusic-wiz-player-controls .ytmusicPlayerControlsPlayPauseButton button, ' +
                '.ytmusicPlayerControlsPlayPauseButton button, ' +
                '#play-pause-button button, ' +
                '#play-pause-button, ' +
                '.play-pause-button button, ' +
                '.play-pause-button'
            );
            const clickPlayBtn = function() {
                if (!playBtn) return false;
                if (typeof window.ymacClick === 'function') {
                    return window.ymacClick(playBtn);
                }
                playBtn.click();
                return true;
            };
            if (v) {
                if (!window.userWantsPlayback || window.isSystemSleeping) {
                    if (!v.paused) {
                        v.pause();
                    }
                    v.muted = true;
                    setTimeout(function() {
                        if (typeof window.__pauseCalls === 'undefined' && (!window.userWantsPlayback || window.isSystemSleeping)) {
                            const vNow = document.querySelector('video');
                            const bar = document.querySelector('ytmusic-player-bar, ytmusic-miniplayer');
                            if (vNow && !vNow.paused) {
                                if (bar && bar.playing === true) {
                                    clickPlayBtn();
                                } else {
                                    vNow.pause();
                                }
                                vNow.muted = true;
                            }
                        }
                    }, 150);
                } else {
                    v.muted = false;
                    if (v.paused) {
                        const p = v.play();
                        if (p && typeof p.catch === 'function') {
                            p.catch(function() {
                                clickPlayBtn();
                            });
                        }
                        if (typeof window.__playCalls === 'undefined') {
                            if (!v.currentSrc && !v.src && v.readyState === 0) {
                                clickPlayBtn();
                            } else {
                                setTimeout(function() {
                                    if (!window.userWantsPlayback || window.isSystemSleeping) return;
                                    const vNow = document.querySelector('video');
                                    if (vNow && vNow.paused) {
                                        clickPlayBtn();
                                        const mp = document.getElementById('movie_player');
                                        if (mp && typeof mp.playVideo === 'function') {
                                            try { mp.playVideo(); } catch (e) {}
                                        }
                                    }
                                }, 180);
                            }
                        }
                    }
                }
            } else if (playBtn) {
                clickPlayBtn();
            }
            if (typeof window.syncYTM === 'function') {
                window.syncYTM(true);
                setTimeout(() => { if (typeof window.syncYTM === 'function') window.syncYTM(true); }, 100);
                setTimeout(() => { if (typeof window.syncYTM === 'function') window.syncYTM(true); }, 300);
            }
        };

        function normStr(str) {
            if (!str) return '';
            return str.toLowerCase()
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .replace(/\([^)]*\)/g, '')
                .replace(/\[[^\]]*\]/g, '')
                .replace(/feat\..*/gi, '')
                .replace(/ft\..*/gi, '')
                .replace(/with\..*/gi, '')
                .replace(/[^\p{L}\p{N}]/gu, '')
                .trim();
        }

        function titlesMatch(t1, t2) {
            const n1 = normStr(t1);
            const n2 = normStr(t2);
            if (!n1 || !n2) return false;
            if (n1 === n2) return true;
            if (n1.length > 3 && n2.length > 3) {
                return n1.includes(n2) || n2.includes(n1);
            }
            return false;
        }

        function getQueueItems() {
            const queuePanel = document.querySelector('ytmusic-player-queue, #queue, ytmusic-playlist-panel-renderer[is-queue]');
            let elements = [];
            if (queuePanel) {
                elements = Array.from(queuePanel.querySelectorAll('ytmusic-player-queue-item, ytmusic-playlist-panel-video-renderer'));
            }
            if (elements.length === 0) {
                const mainContents = document.querySelector('#contents.ytmusic-playlist-video-list-renderer, #items.ytmusic-playlist-panel-renderer');
                if (mainContents) {
                    elements = Array.from(mainContents.querySelectorAll('ytmusic-playlist-panel-video-renderer, ytmusic-responsive-list-item-renderer'));
                }
            }
            if (elements.length === 0) {
                elements = Array.from(document.querySelectorAll('ytmusic-player-queue-item'));
            }
            const filtered = elements.filter(item => {
                if (item.hasAttribute('hidden')) return false;
                if (item.closest('[hidden], [aria-hidden="true"], template, ytmusic-player-bar, ytmusic-miniplayer, ytmusic-wiz-player-controls, #player-bar, ytmusic-playlist-header-renderer, #header')) {
                    return false;
                }
                const style = item.style;
                if (style && style.display === 'none') return false;
                return true;
            });
            const seenWrappers = typeof Set === 'function' ? new Set() : null;
            const deduped = [];
            for (let i = 0; i < filtered.length; i++) {
                const el = filtered[i];
                const prev = deduped.length > 0 ? deduped[deduped.length - 1] : null;
                if (prev && (prev === el || prev.contains(el))) {
                    continue;
                }
                const wrapper = el.closest ? el.closest('ytmusic-playlist-panel-video-wrapper-renderer') : null;
                if (wrapper && seenWrappers) {
                    if (seenWrappers.has(wrapper)) continue;
                    seenWrappers.add(wrapper);
                }
                deduped.push(el);
            }
            return deduped;
        }

        function queryDeep(root, selector) {
            if (!root) return null;
            const direct = root.querySelector(selector);
            if (direct) return direct;
            if (root.shadowRoot) {
                const inShadow = root.shadowRoot.querySelector(selector);
                if (inShadow) return inShadow;
            }
            const descendants = root.querySelectorAll('*');
            for (let i = 0; i < descendants.length; i++) {
                if (descendants[i].shadowRoot) {
                    const nested = queryDeep(descendants[i].shadowRoot, selector);
                    if (nested) return nested;
                }
            }
            return null;
        }
        window.ymacQueryDeep = queryDeep;

        function queryAllDeep(root, selector, depth) {
            const results = [];
            if (!root || (depth || 0) > 6) return results;
            try {
                const direct = root.querySelectorAll(selector);
                for (let i = 0; i < direct.length; i++) results.push(direct[i]);
            } catch (e) {}
            if (root.shadowRoot) {
                const nested = queryAllDeep(root.shadowRoot, selector, (depth || 0) + 1);
                for (let i = 0; i < nested.length; i++) results.push(nested[i]);
            }
            const descendants = root.querySelectorAll('*');
            for (let i = 0; i < descendants.length; i++) {
                if (descendants[i].shadowRoot) {
                    const nested = queryAllDeep(descendants[i].shadowRoot, selector, (depth || 0) + 1);
                    for (let j = 0; j < nested.length; j++) results.push(nested[j]);
                }
            }
            return results;
        }

        const PLAYER_BAR_SELECTOR = 'ytmusic-player-bar, ytmusic-player-controls, ytmusic-miniplayer, ytmusic-wiz-player-controls, #player-bar';

        function isInPlayerBar(el) {
            if (!el) return false;
            return Boolean(el.closest && el.closest(PLAYER_BAR_SELECTOR));
        }

        function findInPlayerBar(selectors) {
            const hasBar = Boolean(document.querySelector(PLAYER_BAR_SELECTOR));
            for (let i = 0; i < selectors.length; i++) {
                let nodes = Array.from(document.querySelectorAll(selectors[i]));
                if (nodes.length === 0) {
                    nodes = queryAllDeep(document, selectors[i], 0);
                }
                for (let j = 0; j < nodes.length; j++) {
                    const el = nodes[j];
                    if (hasBar && !isInPlayerBar(el)) continue;
                    return el;
                }
            }
            return null;
        }

        window.ymacClick = function(el) {
            if (!el) return false;
            const target = (el.tagName === 'BUTTON' ? el : null) ||
                el.querySelector('button, #button') ||
                (el.shadowRoot && el.shadowRoot.querySelector('button, #button')) ||
                el;
            if (typeof target.click === 'function') {
                target.click();
            } else {
                target.dispatchEvent(new MouseEvent('click', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    composed: true,
                    detail: 1
                }));
            }
            return true;
        };

        window.ymacClickControl = function(selectors) {
            if (!Array.isArray(selectors)) return false;
            const hasBar = Boolean(document.querySelector(PLAYER_BAR_SELECTOR));
            for (let i = 0; i < selectors.length; i++) {
                let nodes = Array.from(document.querySelectorAll(selectors[i]));
                if (nodes.length === 0) {
                    nodes = queryAllDeep(document, selectors[i], 0);
                }
                for (let j = 0; j < nodes.length; j++) {
                    const el = nodes[j];
                    if (hasBar && !isInPlayerBar(el)) {
                        continue;
                    }
                    if (el.disabled || el.getAttribute('aria-disabled') === 'true' || el.hasAttribute('hidden')) {
                        continue;
                    }
                    const host = el.closest ? el.closest('yt-icon-button, tp-yt-paper-icon-button, yt-button-shape') : null;
                    if (host && (host.disabled || host.hasAttribute('disabled') || host.hasAttribute('hidden'))) {
                        continue;
                    }
                    if (window.ymacClick(el)) return true;
                }
            }
            return false;
        };

        function getCurrentTrackTitle() {
            let title = '';
            if (navigator.mediaSession && navigator.mediaSession.metadata) {
                title = navigator.mediaSession.metadata.title || '';
            }
            if (!title) {
                const titleEl = findInPlayerBar(['.title', 'yt-formatted-string.title', '.middle-controls .title', '.ytmusicTrackInfoTitle', 'ytmusic-track-info .ytmusicTrackInfoTitle']) ||
                    document.querySelector('ytmusic-player-bar .title, ytmusic-player-bar yt-formatted-string.title, .middle-controls .title, ytmusic-miniplayer .ytmusicTrackInfoTitle');
                title = titleEl ? (titleEl.getAttribute('title') || titleEl.innerText || titleEl.textContent || '').trim() : '';
            }
            return title;
        }

        function findActiveQueueIndex(validItems, title) {
            let activeDomIdx = -1;
            let bestTitleIdx = -1;
            let bestDomSelIdx = -1;

            for (let k = 0; k < validItems.length; k++) {
                const el = validItems[k];
                const tEl = el.querySelector('.song-title, .title, yt-formatted-string.title');
                const tText = tEl ? ((tEl.innerText || '').trim() || (tEl.textContent || '').trim()) : '';
                if (!tText) continue;

                const isDomSelected = el.hasAttribute('selected') || el.classList.contains('selected') || el.getAttribute('play-button-state') === 'playing' || el.querySelector('ytmusic-equalizer') !== null;
                const isTitleMatching = titlesMatch(tText, title);

                if (isDomSelected && isTitleMatching && activeDomIdx === -1) activeDomIdx = k;
                if (isTitleMatching && bestTitleIdx === -1) bestTitleIdx = k;
                if (isDomSelected && bestDomSelIdx === -1) bestDomSelIdx = k;
            }

            if (activeDomIdx === -1) {
                activeDomIdx = bestTitleIdx !== -1 ? bestTitleIdx : bestDomSelIdx;
            }
            return activeDomIdx;
        }

        window.ymacPlayQueueIndex = function(idx) {
            const validItems = getQueueItems();
            if (!validItems || idx < 0 || idx >= validItems.length || !validItems[idx]) {
                return false;
            }
            if (typeof window.setUserWantsPlayback === 'function') {
                window.setUserWantsPlayback(true);
            } else {
                window.userWantsPlayback = true;
            }
            window.isSystemSleeping = false;
            const item = validItems[idx];
            const target =
                item.querySelector('ytmusic-play-button-renderer button') ||
                item.querySelector('ytmusic-play-button-renderer #button') ||
                item.querySelector('ytmusic-play-button-renderer') ||
                item.querySelector('#play-button') ||
                item.querySelector('.play-button') ||
                item.querySelector('a') ||
                item.querySelector('.song-title') ||
                item.querySelector('.title') ||
                item;
            const clicked = window.ymacClick(target);
            if (clicked) {
                [250, 600].forEach(delay => {
                    setTimeout(() => {
                        if (window.userWantsPlayback && !window.isSystemSleeping) {
                            const v = document.querySelector('video');
                            if (v) {
                                v.muted = false;
                                if (v.paused && typeof window.__playCalls === 'undefined') {
                                    const p = v.play();
                                    if (p && typeof p.catch === 'function') { p.catch(function() {}); }
                                }
                            }
                        }
                        if (typeof window.syncYTM === 'function') window.syncYTM(true);
                    }, delay);
                });
            }
            return clicked;
        };

        window.ymacStepQueue = function(delta) {
            const validItems = getQueueItems();
            if (!validItems || validItems.length === 0) return false;
            const activeIdx = findActiveQueueIndex(validItems, getCurrentTrackTitle());
            if (activeIdx === -1) return false;
            const targetIdx = activeIdx + delta;
            if (targetIdx < 0 || targetIdx >= validItems.length) return false;
            return window.ymacPlayQueueIndex(targetIdx);
        };

        // Экспортируем в window для вызова из Swift
        window.getQueueItems = getQueueItems;

        if (!window.__ymacUserInteractionHooked) {
            window.__ymacUserInteractionHooked = true;
            ['pointerdown', 'keydown'].forEach(evtName => {
                document.addEventListener(evtName, function(e) {
                    if (e && e.isTrusted) {
                        window.__ymacLastUserClickTime = Date.now();
                    }
                }, true);
            });
        }

        function attachVideoEvents() {
            const video = document.querySelector('video');
            if (video && video !== window.lastAttachedVideo && !video.__ymacAttached) {
                video.__ymacAttached = true;
                window.lastAttachedVideo = video;
                if (!window.userWantsPlayback || window.isSystemSleeping) {
                    video.muted = true;
                    if (!video.paused) {
                        video.pause();
                    }
                }
                ['play', 'pause', 'ended', 'timeupdate'].forEach(evt => {
                    video.addEventListener(evt, () => {
                        if (evt === 'play') {
                            const hasRecentUserClick = !window.isSystemSleeping && (Date.now() - (window.__ymacLastUserClickTime || 0) < 3500);
                            if (!window.userWantsPlayback && hasRecentUserClick) {
                                window.setUserWantsPlayback(true);
                            }
                            if (!window.userWantsPlayback || window.isSystemSleeping) {
                                if (!video.paused) video.pause();
                                video.muted = true;
                                return;
                            } else {
                                video.muted = false;
                            }
                        }
                        if (evt === 'timeupdate') {
                            const now = Date.now();
                            if (now - (window.__lastTimeUpdateSync || 0) < 500) {
                                return;
                            }
                            window.__lastTimeUpdateSync = now;
                        }
                        syncYTM(evt !== 'timeupdate');
                    });
                });
            }
        }

        function isSupportedPlaylist(href, listId) {
            if (!href || !listId) return false;
            if (href.includes('watch?v=')) return false;
            return (
                listId.startsWith('PL') ||
                listId.startsWith('LM') ||
                listId.startsWith('LL') ||
                listId.startsWith('FL') ||
                listId.startsWith('SE') ||
                listId.startsWith('RDCLAK')
            );
        }

        function detectRepeatMode() {
            const playerBar = document.querySelector('ytmusic-player-bar');
            const playerControls = document.querySelector('ytmusic-player-controls, ytmusic-wiz-player-controls');
            const repeatBtn = findInPlayerBar([
                'ytmusic-player-bar .repeat',
                'ytmusic-player-bar .repeat-button',
                'ytmusic-player-controls .repeat',
                'ytmusic-miniplayer .ytmusicPlayerControlsRepeatButton button',
                'ytmusic-wiz-player-controls .ytmusicPlayerControlsRepeatButton button',
                '.ytmusicPlayerControlsRepeatButton button',
                '.ytmusicPlayerControlsRepeatButton',
                '.repeat',
                '.repeat-button'
            ]);

            const repeatAttr = (
                (repeatBtn && (repeatBtn.repeatMode || repeatBtn.getAttribute('repeat-mode') || repeatBtn.getAttribute('data-repeat-mode'))) ||
                (playerBar && (playerBar.repeatMode || playerBar.getAttribute('repeat-mode'))) ||
                (playerControls && (playerControls.repeatMode || playerControls.getAttribute('repeat-mode'))) ||
                ''
            ).toString().toUpperCase();
            if (repeatAttr === 'ONE' || repeatAttr === 'REPEAT_ONE') return 2;
            if (repeatAttr === 'ALL' || repeatAttr === 'REPEAT_ALL') return 1;
            if (repeatAttr === 'NONE' || repeatAttr === 'OFF') return 0;

            if (!repeatBtn) return 0;

            const innerBtn = repeatBtn.querySelector('button') || (repeatBtn.shadowRoot && repeatBtn.shadowRoot.querySelector('button'));
            const iconEl = repeatBtn.querySelector('yt-icon, iron-icon') || (repeatBtn.shadowRoot && repeatBtn.shadowRoot.querySelector('yt-icon, iron-icon'));
            const iconName = (iconEl ? (iconEl.icon || iconEl.getAttribute('icon') || '') : '').toLowerCase();
            const iconHtml = (repeatBtn.innerHTML || '').toLowerCase();
            if (
                iconName.includes('repeat_one') ||
                iconName.includes('repeat-one') ||
                iconName.includes('loop_one') ||
                iconHtml.includes('repeat_one') ||
                iconHtml.includes('repeat-one') ||
                iconHtml.includes('repeatone') ||
                iconHtml.includes('loop_one')
            ) {
                return 2;
            }
            if (iconName.includes('loop_active') || iconHtml.includes('loop_active')) {
                return 1;
            }

            const rawLabel = (
                repeatBtn.getAttribute('aria-label') ||
                repeatBtn.getAttribute('title') ||
                (innerBtn && (innerBtn.getAttribute('aria-label') || innerBtn.getAttribute('title'))) ||
                ''
            ).toLowerCase();
            const normLabel = ' ' + rawLabel
                .normalize('NFD')
                .replace(/[\u0300-\u036f]/g, '')
                .replace(/[^\p{L}\p{N}]+/gu, ' ')
                .trim() + ' ';

            const offTokens = [
                ' off ', ' none ',
                ' deaktiviert ', ' aus ', ' nicht ',
                ' выключен ', ' выкл ', ' не ',
                ' вимкнено ', ' вимк ',
                ' desactivada ', ' desactivar ',
                ' desativada ', ' desativar ', ' nao ',
                ' disattivata ', ' disattiva ', ' nessuno ', ' non ',
                ' desactivee ', ' desactiver ', ' pas ',
                ' dezactivata ', ' nu ', ' fara ',
                ' wylaczone ', ' wyłączone ', ' wylacz ', ' wyłącz ', ' nie '
            ];
            if (offTokens.some(tok => normLabel.includes(tok))) {
                return 0;
            }

            const oneTokens = [
                ' one ', ' 1 ', ' single ', ' current ',
                ' titel ', ' einen ', ' einzelnen ',
                ' один ', ' одну ', ' одного ', ' одна ', ' цієї ', ' цього ', ' поточної ', ' поточнои ', ' трек ', ' трека ', ' треку ', ' композицию ', ' композицію ', ' композиції ', ' пісню ', ' пісні ', ' песню ', ' одной ', ' однієї ',
                ' una ', ' uno ', ' cancion ', ' pista ',
                ' uma ', ' um ', ' musica ', ' faixa ',
                ' brano ', ' traccia ',
                ' titre ', ' un ', ' chanson ',
                ' melodia ', ' melodie ', ' piesa ', ' unul ',
                ' jeden ', ' jedna ', ' utwor '
            ];
            if (oneTokens.some(tok => normLabel.includes(tok))) {
                return 2;
            }

            const allTokens = [
                ' all ', ' alle ', ' alles ',
                ' все ', ' всі ', ' всех ', ' усіх ', ' всіх ',
                ' todo ', ' todas ', ' tudo ',
                ' tutti ', ' tutto ', ' tutte ',
                ' tout ', ' tot ', ' toate ',
                ' wszystko ', ' wszystkie '
            ];
            if (allTokens.some(tok => normLabel.includes(tok))) {
                return 1;
            }

            const isPressed =
                repeatBtn.getAttribute('aria-pressed') === 'true' ||
                (innerBtn && innerBtn.getAttribute('aria-pressed') === 'true') ||
                repeatBtn.classList.contains('active') ||
                (innerBtn && innerBtn.classList.contains('active'));
            return isPressed ? 1 : 0;
        }

        window.syncYTM = function(isStateChange) {
            try {
                attachVideoEvents();
                const video = document.querySelector('video');

                if ((!window.userWantsPlayback || window.isSystemSleeping) && video) {
                    const hasRecentUserClick = !window.isSystemSleeping && (Date.now() - (window.__ymacLastUserClickTime || 0) < 3500);
                    if (!video.paused && hasRecentUserClick) {
                        window.setUserWantsPlayback(true);
                        video.muted = false;
                    } else {
                        if (!video.paused) {
                            video.pause();
                        }
                        video.muted = true;
                    }
                }

                const now = Date.now();
                const isFullSync = isStateChange || (now - window.lastFullSyncTime > 1800);
                if (isFullSync) window.lastFullSyncTime = now;

                const listMatch = window.location.href.match(/list=([a-zA-Z0-9_-]+)/);
                const mp = document.getElementById('movie_player');
                const mpListId = (mp && typeof mp.getPlaylistId === 'function') ? (mp.getPlaylistId() || '') : '';
                const qHdrLink = document.querySelector('ytmusic-queue-header-renderer a[href*="list="], ytmusic-player-page a[href*="list="]');
                const qHdrHref = qHdrLink ? (qHdrLink.getAttribute('href') || '') : '';
                const qHdrMatch = qHdrHref.match(/list=([a-zA-Z0-9_-]+)/);
                let currentListId = (listMatch ? listMatch[1] : '') || mpListId || (qHdrMatch ? qHdrMatch[1] : '');
                if (currentListId.startsWith('VL') && currentListId.length > 2) {
                    currentListId = currentListId.slice(2);
                }

                if (!window.hasTriggeredGuide) {
                    const hasPlaylistsInGuide = document.querySelector(
                        'ytmusic-guide-section-renderer ytmusic-guide-entry-renderer a[href*="list="], ' +
                        '#guide-content a[href*="list="], ' +
                        '#sections a[href*="list="], ' +
                        '#guide a[href*="list="], ' +
                        'tp-yt-paper-item a[href*="list="]'
                    ) !== null;

                    if (hasPlaylistsInGuide) {
                        window.hasTriggeredGuide = true;
                    } else {
                        const guideEl = document.querySelector('#guide, tp-yt-app-drawer#guide');
                        const gBtn = document.querySelector(
                            'ytmusic-nav-bar #guide-button button, ' +
                            'ytmusic-guide-button button, ' +
                            'tp-yt-paper-icon-button#guide-button'
                        );
                        if (gBtn) {
                            const isGuideCollapsed = guideEl
                                ? (
                                    guideEl.hasAttribute('collapsed') ||
                                    guideEl.getAttribute('aria-hidden') === 'true' ||
                                    guideEl.getAttribute('aria-expanded') === 'false' ||
                                    guideEl.style.display === 'none' ||
                                    gBtn.getAttribute('aria-expanded') === 'false' ||
                                    (!guideEl.hasAttribute('opened') && guideEl.getAttribute('aria-expanded') !== 'true' && gBtn.getAttribute('aria-expanded') !== 'true')
                                )
                                : (gBtn.getAttribute('aria-expanded') === 'false');

                            if (isGuideCollapsed) {
                                gBtn.click();
                                window.hasTriggeredGuide = true;
                                setTimeout(() => { if (gBtn) gBtn.click(); }, 350);
                            }
                        }
                    }
                }

                const playerBar = document.querySelector('ytmusic-player-bar');
                const playerControls = document.querySelector('ytmusic-player-controls');
                const miniPlayer = document.querySelector('ytmusic-miniplayer');
                const wizControls = document.querySelector('ytmusic-wiz-player-controls');
                const isWatchPage = window.location.href.includes('watch?');
                const hasPlayerUI = Boolean(playerBar || playerControls || miniPlayer || wizControls || isWatchPage);

                const isPlaying = video ? (!video.paused && !video.ended && video.readyState > 1 && !!window.userWantsPlayback && !window.isSystemSleeping) : false;
                const currentTime = (hasPlayerUI || isPlaying) && video && !isNaN(video.currentTime) ? video.currentTime : 0;
                const duration = (hasPlayerUI || isPlaying) && video && !isNaN(video.duration) && isFinite(video.duration) ? video.duration : 0;

                let title = '';
                let artist = '';
                if (hasPlayerUI || isPlaying) {
                    if (navigator.mediaSession && navigator.mediaSession.metadata) {
                        title = navigator.mediaSession.metadata.title || '';
                        artist = navigator.mediaSession.metadata.artist || '';
                    }

                    if (!title) {
                        const titleEl = findInPlayerBar(['.title', 'yt-formatted-string.title', '.middle-controls .title', '.ytmusicTrackInfoTitle', 'ytmusic-track-info .ytmusicTrackInfoTitle']) ||
                            document.querySelector('ytmusic-player-bar .title, ytmusic-player-bar yt-formatted-string.title, .middle-controls .title, ytmusic-miniplayer .ytmusicTrackInfoTitle');
                        title = titleEl ? (titleEl.getAttribute('title') || titleEl.innerText || titleEl.textContent || '').trim() : '';
                    }
                    if (!artist) {
                        const artistEl = findInPlayerBar(['.ytmusicTrackInfoByline a', '.ytmusicTrackInfoByline', '.byline', 'yt-formatted-string.byline', '.subtitle']) ||
                            document.querySelector('ytmusic-player-bar .byline, ytmusic-player-bar yt-formatted-string.byline, ytmusic-player-bar .subtitle, ytmusic-miniplayer .ytmusicTrackInfoByline a');
                        artist = artistEl ? (artistEl.getAttribute('title') || artistEl.innerText || artistEl.textContent || '').trim() : '';
                    }
                }

                let artworkUrl = '';
                if (hasPlayerUI || isPlaying) {
                    if (navigator.mediaSession?.metadata?.artwork?.length) {
                        const arts = navigator.mediaSession.metadata.artwork;
                        artworkUrl = arts[arts.length - 1].src || '';
                    }
                    if (!artworkUrl) {
                        const imgEl = findInPlayerBar(['img.image', '.thumbnail-image-wrapper img', '#song-image img', 'img.ytmusicTrackInfoThumbnail']) ||
                            document.querySelector('ytmusic-player-bar img.image, .thumbnail-image-wrapper img, #song-image img, ytmusic-miniplayer img.ytmusicTrackInfoThumbnail');
                        artworkUrl = imgEl ? imgEl.src : '';
                    }
                    if (artworkUrl) {
                        artworkUrl = artworkUrl.replace(/=w[0-9]+-h[0-9]+[^&]*/, '=w512-h512-l90-rj').replace(/=s[0-9]+[^&]*/, '=s512');
                    }
                }

                const likeRenderer = findInPlayerBar(['ytmusic-like-button-renderer']) || document.querySelector('ytmusic-like-button-renderer');
                const likeStatus = likeRenderer ? (likeRenderer.likeStatus || (likeRenderer.data && likeRenderer.data.likeStatus) || likeRenderer.getAttribute('like-status') || '').toString().toUpperCase() : '';
                const likeScope = likeRenderer || findInPlayerBar(['segmented-like-dislike-button-view-model', 'ytmusic-miniplayer']) || document;

                const likeBtn = queryDeep(likeScope, 'like-button-view-model button, .ytLikeButtonViewModelHost button, #button-shape-like button, .like button, .like-button button, #button-shape-like tp-yt-paper-icon-button') ||
                    findInPlayerBar(['like-button-view-model button', '.ytLikeButtonViewModelHost button']);
                const likeBtnPressed = likeBtn ? (likeBtn.getAttribute('aria-pressed') === 'true' || likeBtn.classList.contains('active')) : false;

                const dislikeBtn = queryDeep(likeScope, 'dislike-button-view-model button, .ytDislikeButtonViewModelHost button, #button-shape-dislike button, .dislike button, .dislike-button button, #button-shape-dislike tp-yt-paper-icon-button') ||
                    findInPlayerBar(['dislike-button-view-model button', '.ytDislikeButtonViewModelHost button']);
                const dislikeBtnPressed = dislikeBtn ? (dislikeBtn.getAttribute('aria-pressed') === 'true' || dislikeBtn.classList.contains('active')) : false;

                const isLiked = likeBtnPressed || (!dislikeBtnPressed && likeStatus === 'LIKE');
                const isDisliked = !isLiked && (dislikeBtnPressed || likeStatus === 'DISLIKE');

                const repeatMode = detectRepeatMode();

                const shuffleBtn = findInPlayerBar([
                    'ytmusic-player-bar .shuffle',
                    'ytmusic-player-bar .shuffle-button',
                    'ytmusic-player-controls .shuffle',
                    'ytmusic-miniplayer .ytmusicPlayerControlsShuffleButton button',
                    'ytmusic-wiz-player-controls .ytmusicPlayerControlsShuffleButton button',
                    '.ytmusicPlayerControlsShuffleButton button',
                    '.ytmusicPlayerControlsShuffleButton',
                    '.shuffle',
                    '.shuffle-button'
                ]);
                const innerShuffleBtn = shuffleBtn ? (shuffleBtn.querySelector('button') || (shuffleBtn.shadowRoot && shuffleBtn.shadowRoot.querySelector('button'))) : null;
                const shuffleAriaEl = (shuffleBtn && shuffleBtn.hasAttribute('aria-pressed'))
                    ? shuffleBtn
                    : (innerShuffleBtn && innerShuffleBtn.hasAttribute('aria-pressed') ? innerShuffleBtn : null);
                let hasDetectedShuffle = false;
                let isShuffle = false;
                if (playerBar && typeof playerBar.shuffleOn === 'boolean') {
                    hasDetectedShuffle = true;
                    isShuffle = playerBar.shuffleOn;
                } else if (playerControls && typeof playerControls.shuffleOn === 'boolean') {
                    hasDetectedShuffle = true;
                    isShuffle = playerControls.shuffleOn;
                } else if (shuffleAriaEl) {
                    hasDetectedShuffle = true;
                    isShuffle = shuffleAriaEl.getAttribute('aria-pressed') === 'true';
                } else if (shuffleBtn && (shuffleBtn.classList.contains('active') || (innerShuffleBtn && innerShuffleBtn.classList.contains('active')))) {
                    hasDetectedShuffle = true;
                    isShuffle = true;
                }

                let queue = [];
                let playlists = [];

                if (isFullSync) {
                    const validItems = getQueueItems();
                    const activeDomIdx = findActiveQueueIndex(validItems, title);

                    const rawQueue = [];
                    const seenMap = {};
                    let prevDomNode = null;

                    validItems.forEach((item, idx) => {
                        if (prevDomNode && (prevDomNode === item || prevDomNode.contains(item))) {
                            return;
                        }
                        prevDomNode = item;

                        const qTitleEl = item.querySelector('.song-title, .title, yt-formatted-string.title');
                        const qArtistEl = item.querySelector('.byline, .author, .subtitle, yt-formatted-string.byline');
                        const qTitle = qTitleEl ? ((qTitleEl.innerText || '').trim() || (qTitleEl.textContent || '').trim()) : '';
                        const qArtist = qArtistEl ? ((qArtistEl.innerText || '').trim() || (qArtistEl.textContent || '').trim()) : '';
                        if (!qTitle) return;

                        const dedupeKey = idx + '_' + (normStr(qTitle) || qTitle);
                        const isCurrentActive = idx === activeDomIdx;
                        if (seenMap.hasOwnProperty(dedupeKey)) {
                            const existingIndex = seenMap[dedupeKey];
                            if (isCurrentActive) {
                                rawQueue[existingIndex].isSelected = true;
                                rawQueue[existingIndex].originalIndex = idx;
                                rawQueue[existingIndex].title = qTitle;
                                if (qArtist) rawQueue[existingIndex].artist = qArtist;
                            }
                            return;
                        }

                        const queueIndex = rawQueue.length;
                        seenMap[dedupeKey] = queueIndex;

                        rawQueue.push({
                            id: 'q_' + idx + '_' + encodeURIComponent(qTitle),
                            originalIndex: idx,
                            title: qTitle,
                            artist: qArtist,
                            isSelected: isCurrentActive
                        });
                    });

                    const selectedIdx = rawQueue.findIndex(i => i.isSelected);
                    queue = rawQueue;
                    if (selectedIdx > 10) {
                        queue = rawQueue.slice(selectedIdx - 10);
                    }

                    const ignoreTerms = [
                        'главная', 'обзор', 'библиотека', 'настройки', 'подкасты', 'чарты',
                        'home', 'explore', 'library', 'podcasts', 'charts', 'settings',
                        'улучшить', 'upgrade', 'радио', 'radio', 'startseite', 'entdecken',
                        'mediathek', 'inicio', 'explorar', 'biblioteca', 'boletim', 'esplora'
                    ];

                    const isLibraryPlaylistsPage = window.location.href.includes('/library/playlists');
                    const seenPlaylists = {};
                    const normalizePlaylistId = function(rawId) {
                        if (!rawId) return '';
                        return (rawId.startsWith('VL') && rawId.length > 2) ? rawId.slice(2) : rawId;
                    };

                    const guideEntries = document.querySelectorAll(
                        'ytmusic-guide-section-renderer ytmusic-guide-entry-renderer a[href*="list="], ' +
                        '#guide-content a[href*="list="], ' +
                        '#sections a[href*="list="], ' +
                        'tp-yt-paper-item a[href*="list="]'
                    );

                    guideEntries.forEach(link => {
                        const href = link.getAttribute('href');
                        if (!href) return;

                        const listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                        if (!listMatch) return;
                        const listId = normalizePlaylistId(listMatch[1]);

                        const isPersonalList = isSupportedPlaylist(href, listId);

                        let rawText = (link.innerText || '').trim();
                        if (!rawText) rawText = (link.textContent || '').trim();
                        let text = rawText ? (rawText.split('\n').map(s => s.trim()).filter(Boolean)[0] || '') : '';
                        const lowerText = text.toLowerCase();

                        const isSystem = ignoreTerms.some(term => lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade'));

                        if (isPersonalList && text && text.length > 0 && text.length < 120 && !seenPlaylists[listId] && !isSystem) {
                            seenPlaylists[listId] = true;
                            playlists.push({ id: listId, title: text, path: href });
                        }
                    });

                    const cardItems = document.querySelectorAll('ytmusic-two-row-item-renderer, ytmusic-responsive-list-item-renderer');

                    cardItems.forEach(item => {
                        const link = item.querySelector('a[href*="list="]');
                        if (!link) return;

                        const href = link.getAttribute('href');
                        if (!href) return;

                        const listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                        if (!listMatch) return;
                        const listId = normalizePlaylistId(listMatch[1]);
                        if (seenPlaylists[listId]) return;

                        const isPersonalList = isSupportedPlaylist(href, listId);

                        const badge = item.querySelector('ytmusic-inline-badge-renderer, .badge');
                        const isPinned = badge ? (
                            (badge.innerText && (badge.innerText.includes('Закріп') || badge.innerText.includes('Pinned') || badge.innerText.includes('Закреп') || badge.innerText.includes('Angepinnt') || badge.innerText.includes('Fijado'))) ||
                            (badge.innerHTML && (badge.innerHTML.includes('Закріп') || badge.innerHTML.includes('Pinned') || badge.innerHTML.includes('Закреп') || badge.innerHTML.includes('Angepinnt') || badge.innerHTML.includes('Fijado')))
                        ) : false;

                        const titleEl = item.querySelector('.title-group .title, .title, yt-formatted-string');
                        let rawCardText = titleEl ? ((titleEl.innerText || '').trim() || (titleEl.textContent || '').trim()) : '';
                        let text = rawCardText ? (rawCardText.split('\n').map(s => s.trim()).filter(Boolean)[0] || '') : '';
                        const lowerText = text.toLowerCase();

                        const isSystem = ignoreTerms.some(term => lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade'));

                        if (isPersonalList && (isPinned || isLibraryPlaylistsPage) && text && text.length > 0 && text.length < 120 && !seenPlaylists[listId] && !isSystem) {
                            seenPlaylists[listId] = true;
                            playlists.push({ id: listId, title: text, path: href });
                        }
                    });
                }

                const signInBtn = document.querySelector('a[href*="ServiceLogin"], ytmusic-sign-in-button-renderer, a[href*="accounts.google.com"], .sign-in-link');
                const avatarBtn = document.querySelector('#avatar-btn, ytmusic-avatar-button, img#img[src*="googleusercontent"], tp-yt-paper-icon-button#account-button');
                const hasPlaylistsInDom = (playlists && playlists.length > 0) || (queue && queue.length > 0);

                let isLoggedIn = true;
                if (signInBtn !== null && !hasPlaylistsInDom && avatarBtn === null) {
                    isLoggedIn = false;
                } else if (avatarBtn !== null || hasPlaylistsInDom) {
                    isLoggedIn = true;
                } else {
                    isLoggedIn = (window.lastKnownLoggedIn !== undefined) ? window.lastKnownLoggedIn : true;
                }
                window.lastKnownLoggedIn = isLoggedIn;

                const payload = {
                    isLoggedIn: isLoggedIn,
                    isPlaying: isPlaying,
                    currentTime: currentTime,
                    duration: duration,
                    title: title,
                    artist: artist,
                    artworkUrl: artworkUrl,
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    repeatMode: repeatMode,
                    currentListId: currentListId
                };

                if (hasDetectedShuffle) {
                    payload.isShuffle = isShuffle;
                }

                if (isFullSync) {
                    payload.queue = queue;
                    payload.playlists = playlists;
                    payload.isLibraryPage = window.location.href.includes('/library/playlists');
                }

                window.webkit?.messageHandlers?.ytmBridge?.postMessage(payload);
            } catch (error) {}
        };

        attachVideoEvents();
        setInterval(() => window.syncYTM(false), 1800);
    })();
    """#
}
