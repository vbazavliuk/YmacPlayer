import Foundation

// MARK: - JavaScript Injection Helpers

/// Provides JavaScript scripts to be injected into the WKWebView for synchronizing YouTube Music player state with Ymac Player.
enum YTMJavaScript {

    /// Injection script that monitors playback state, queue, playlists, and user authentication, posting structured updates to the native handler.
    static let syncScript = #"""
    (() => {
        window.hasTriggeredGuide = false;
        window.hasAutoPausedInitial = false;
        window.isSystemSleeping = false;
        window.userWantsPlayback = false;
        window.lastAttachedVideo = null;
        window.lastFullSyncTime = 0;

        window.setPlaybackIntent = function(wantsPlayback) {
            window.userWantsPlayback = !!wantsPlayback;
            const v = document.querySelector('video');
            if (v) {
                if (!window.userWantsPlayback || window.isSystemSleeping) {
                    v.pause();
                    v.muted = true;
                } else {
                    v.muted = false;
                    v.play().catch(function() {});
                }
            }
            if (typeof window.syncYTM === 'function') {
                window.syncYTM(true);
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
            return elements.filter(item => !item.closest('ytmusic-player-bar, #player-bar, ytmusic-playlist-header-renderer, #header'));
        }

        // Экспортируем в window для вызова из Swift
        window.getQueueItems = getQueueItems;

        function attachVideoEvents() {
            const video = document.querySelector('video');
            if (video && video !== window.lastAttachedVideo) {
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
                            if (!window.userWantsPlayback || window.isSystemSleeping) {
                                video.pause();
                                video.muted = true;
                                return;
                            } else {
                                video.muted = false;
                            }
                        }
                        syncYTM(evt !== 'timeupdate');
                    });
                });
            }
        }

        window.syncYTM = function(isStateChange) {
            try {
                attachVideoEvents();
                const video = document.querySelector('video');

                if ((!window.userWantsPlayback || window.isSystemSleeping) && video) {
                    if (!video.paused) {
                        video.pause();
                    }
                    video.muted = true;
                }

                const now = Date.now();
                const isFullSync = isStateChange || (now - window.lastFullSyncTime > 1800);
                if (isFullSync) window.lastFullSyncTime = now;

                const listMatch = window.location.href.match(/list=([a-zA-Z0-9_-]+)/);
                const currentListId = listMatch ? listMatch[1] : '';

                if (!window.hasTriggeredGuide) {
                    const gBtn = document.querySelector('ytmusic-guide-button button, #guide-button button, tp-yt-paper-icon-button#button');
                    if (gBtn) {
                        gBtn.click();
                        window.hasTriggeredGuide = true;
                        setTimeout(() => { if (gBtn) gBtn.click(); }, 350);
                    }
                }

                const isPlaying = video ? (!video.paused && video.currentTime > 0 && video.readyState > 2 && !!window.userWantsPlayback && !window.isSystemSleeping) : false;
                const currentTime = (video && !isNaN(video.currentTime)) ? video.currentTime : 0;
                const duration = (video && !isNaN(video.duration) && isFinite(video.duration)) ? video.duration : 0;

                let title = '';
                let artist = '';
                if (navigator.mediaSession && navigator.mediaSession.metadata) {
                    title = navigator.mediaSession.metadata.title || '';
                    artist = navigator.mediaSession.metadata.artist || '';
                }

                if (!title) {
                    const titleEl = document.querySelector('ytmusic-player-bar .title, ytmusic-player-bar yt-formatted-string.title, .middle-controls .title');
                    title = titleEl ? (titleEl.getAttribute('title') || titleEl.innerText || '').trim() : '';
                }
                if (!artist) {
                    const artistEl = document.querySelector('ytmusic-player-bar .byline, ytmusic-player-bar yt-formatted-string.byline, ytmusic-player-bar .subtitle');
                    artist = artistEl ? (artistEl.getAttribute('title') || artistEl.innerText || '').trim() : '';
                }

                let artworkUrl = '';
                if (navigator.mediaSession?.metadata?.artwork?.length) {
                    const arts = navigator.mediaSession.metadata.artwork;
                    artworkUrl = arts[arts.length - 1].src || '';
                }
                if (!artworkUrl) {
                    const imgEl = document.querySelector('ytmusic-player-bar img.image, .thumbnail-image-wrapper img, #song-image img');
                    artworkUrl = imgEl ? imgEl.src : '';
                }
                if (artworkUrl) {
                    artworkUrl = artworkUrl.replace(/=w[0-9]+-h[0-9]+[^&]*/, '=w512-h512-l90-rj').replace(/=s[0-9]+[^&]*/, '=s512');
                }

                const likeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-like button, ytmusic-like-button-renderer .like-button button');
                const isLiked = likeBtn ? (likeBtn.getAttribute('aria-pressed') === 'true' || likeBtn.classList.contains('active')) : false;

                const dislikeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button, ytmusic-like-button-renderer .dislike-button button');
                const isDisliked = dislikeBtn ? (dislikeBtn.getAttribute('aria-pressed') === 'true' || dislikeBtn.classList.contains('active')) : false;

                const repeatBtn = document.querySelector('ytmusic-player-bar .repeat-button, ytmusic-player-bar tp-yt-paper-icon-button.repeat-button');
                let repeatMode = 0;
                if (repeatBtn) {
                    const ariaLabel = (repeatBtn.getAttribute('aria-label') || repeatBtn.getAttribute('title') || '').toLowerCase();
                    const iconHtml = (repeatBtn.innerHTML || '').toLowerCase();
                    const isPressed = repeatBtn.getAttribute('aria-pressed') === 'true' || repeatBtn.classList.contains('active');

                    if (iconHtml.includes('repeat_one') || iconHtml.includes('repeat-one') || ariaLabel.includes('one') || ariaLabel.includes('1') || ariaLabel.includes('один') || ariaLabel.includes('одну')) {
                        repeatMode = 2;
                    } else if (isPressed || ariaLabel.includes('all') || ariaLabel.includes('все') || ariaLabel.includes('всі') || ariaLabel.includes('alle') || ariaLabel.includes('tutti')) {
                        repeatMode = 1;
                    }
                }

                let queue = [];
                let playlists = [];

                if (isFullSync) {
                    const validItems = getQueueItems();
                    let activeDomIdx = -1;
                    let bestTitleIdx = -1;
                    let bestDomSelIdx = -1;

                    for (let k = 0; k < validItems.length; k++) {
                        const el = validItems[k];
                        const tEl = el.querySelector('.song-title, .title, yt-formatted-string.title');
                        const tText = tEl ? (tEl.innerText || tEl.textContent || '').trim() : '';
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

                    const rawQueue = [];
                    const seenMap = {};

                    validItems.forEach((item, idx) => {
                        const qTitleEl = item.querySelector('.song-title, .title, yt-formatted-string.title');
                        const qArtistEl = item.querySelector('.byline, .author, .subtitle, yt-formatted-string.byline');
                        const qTitle = qTitleEl ? (qTitleEl.innerText || qTitleEl.textContent || '').trim() : '';
                        const qArtist = qArtistEl ? (qArtistEl.innerText || qArtistEl.textContent || '').trim() : '';
                        if (!qTitle) return;

                        const dedupeKey = normStr(qTitle);
                        if (!dedupeKey) return;

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
                            id: 'q_' + queueIndex + '_' + encodeURIComponent(qTitle),
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
                        const listId = listMatch[1];

                        const isPersonalList =
                            (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                            !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');

                        let text = link.innerText ? link.innerText.trim() : '';
                        if (text) text = text.split('\n')[0].trim();
                        const lowerText = text.toLowerCase();

                        const isSystem = ignoreTerms.some(term => lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade'));

                        if (isPersonalList && text && text.length > 0 && text.length < 60 && !seenPlaylists[listId] && !isSystem) {
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
                        const listId = listMatch[1];
                        if (seenPlaylists[listId]) return;

                        const isPersonalList =
                            (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                            !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');

                        const badge = item.querySelector('ytmusic-inline-badge-renderer, .badge');
                        const isPinned = badge ? (
                            (badge.innerText && (badge.innerText.includes('Закріп') || badge.innerText.includes('Pinned') || badge.innerText.includes('Закреп') || badge.innerText.includes('Angepinnt') || badge.innerText.includes('Fijado'))) ||
                            (badge.innerHTML && (badge.innerHTML.includes('Закріп') || badge.innerHTML.includes('Pinned') || badge.innerHTML.includes('Закреп') || badge.innerHTML.includes('Angepinnt') || badge.innerHTML.includes('Fijado')))
                        ) : false;

                        const titleEl = item.querySelector('.title-group .title, .title, yt-formatted-string');
                        let text = titleEl ? (titleEl.innerText || titleEl.textContent || '').trim() : '';
                        if (text) text = text.split('\n')[0].trim();
                        const lowerText = text.toLowerCase();

                        const isSystem = ignoreTerms.some(term => lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade'));

                        if (isPersonalList && (isPinned || isLibraryPlaylistsPage) && text && text.length > 0 && text.length < 60 && !isSystem) {
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

                if (isFullSync) {
                    payload.queue = queue;
                    payload.playlists = playlists;
                }

                window.webkit.messageHandlers.ytmBridge.postMessage(payload);
            } catch (error) {}
        };

        setInterval(() => window.syncYTM(false), 1800);
    })();
    """#
}
