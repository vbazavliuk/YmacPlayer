import Foundation

// MARK: - JavaScript Injection Helpers

/// Provides JavaScript scripts to be injected into the WKWebView for synchronizing YouTube Music player state with Ymac Player.
enum YTMJavaScript {

    /// Injection script that monitors playback state, queue, playlists, and user authentication, posting structured updates to the `ytmBridge` native handler.
    static let syncScript = #"""
    window.hasTriggeredGuide = false;
    window.hasAutoPausedInitial = false;
    window.attachedVideoListeners = false;
    window.lastFullSyncTime = 0;

    function normStr(str) {
        if (!str) return '';
        return str.toLowerCase()
            .replace(/\([^)]*\)/g, '')
            .replace(/\[[^\]]*\]/g, '')
            .replace(/feat\..*/gi, '')
            .replace(/ft\..*/gi, '')
            .replace(/with\..*/gi, '')
            .replace(/[^a-z0-9а-яіїєґ]/gi, '')
            .trim();
    }

    function titlesMatch(t1, t2) {
        var n1 = normStr(t1);
        var n2 = normStr(t2);

        if (!n1 || !n2) return false;
        if (n1 === n2) return true;

        if (n1.length > 3 && n2.length > 3) {
            if (n1.indexOf(n2) !== -1 || n2.indexOf(n1) !== -1) {
                return true;
            }
        }
        return false;
    }

    function getQueueItems() {
        var queuePanel =
            document.querySelector('ytmusic-player-queue') ||
            document.querySelector('#queue') ||
            document.querySelector('ytmusic-playlist-panel-renderer[is-queue]');

        var elements = [];

        if (queuePanel) {
            elements = queuePanel.querySelectorAll('ytmusic-player-queue-item');
            if (!elements || elements.length === 0) {
                elements = queuePanel.querySelectorAll('ytmusic-playlist-panel-video-renderer');
            }
        }

        if (!elements || elements.length === 0) {
            var mainContents =
                document.querySelector('#contents.ytmusic-playlist-video-list-renderer') ||
                document.querySelector('#items.ytmusic-playlist-panel-renderer');

            if (mainContents) {
                elements = mainContents.querySelectorAll(
                    'ytmusic-playlist-panel-video-renderer, ytmusic-responsive-list-item-renderer'
                );
            }
        }

        if (!elements || elements.length === 0) {
            elements = document.querySelectorAll('ytmusic-player-queue-item');
        }

        var valid = [];
        elements.forEach(function(item) {
            if (
                item.closest('ytmusic-player-bar') ||
                item.closest('#player-bar') ||
                item.closest('ytmusic-playlist-header-renderer') ||
                item.closest('ytmusic-responsive-header-renderer') ||
                item.closest('ytmusic-editable-playlist-detail-header-renderer') ||
                item.closest('ytmusic-detail-header-renderer') ||
                item.closest('#header') ||
                item.closest('.header')
            ) {
                return;
            }
            valid.push(item);
        });

        return valid;
    }

    function attachVideoEvents() {
        var video = document.querySelector('video');
        if (video && !window.attachedVideoListeners) {
            window.attachedVideoListeners = true;
            ['play', 'pause', 'ended', 'timeupdate'].forEach(function(evt) {
                video.addEventListener(evt, function() {
                    syncYTM(true);
                });
            });
        }
    }

    function syncYTM(isEventTriggered) {
        try {
            attachVideoEvents();

            var now = Date.now();
            var isFullSync = !isEventTriggered || (now - window.lastFullSyncTime > 1800);

            if (isFullSync) {
                window.lastFullSyncTime = now;
            }

            var video = document.querySelector('video');
            var isPlaylistUrl =
                window.location.href.includes('list=') ||
                window.location.href.includes('browse/');

            if (!isPlaylistUrl && !window.hasAutoPausedInitial && video && !video.paused) {
                video.pause();
                window.hasAutoPausedInitial = true;
            }

            if (!window.hasTriggeredGuide) {
                var gBtn =
                    document.querySelector('ytmusic-guide-button button') ||
                    document.querySelector('#guide-button button') ||
                    document.querySelector('tp-yt-paper-icon-button#button');

                if (gBtn) {
                    gBtn.click();
                    window.hasTriggeredGuide = true;
                    setTimeout(function() {
                        if (gBtn) gBtn.click();
                    }, 350);
                }
            }

            var isPlaying = video
                ? (!video.paused && video.currentTime > 0 && video.readyState > 2)
                : false;

            var currentTime = video ? video.currentTime : 0;
            var duration = video && !isNaN(video.duration) ? video.duration : 0;

            var title = '';
            var artist = '';

            if (navigator.mediaSession && navigator.mediaSession.metadata) {
                title = navigator.mediaSession.metadata.title || '';
                artist = navigator.mediaSession.metadata.artist || '';
            }

            if (!title) {
                var titleEl =
                    document.querySelector('ytmusic-player-bar .title') ||
                    document.querySelector('ytmusic-player-bar yt-formatted-string.title') ||
                    document.querySelector('.middle-controls .title');

                title = titleEl
                    ? (titleEl.getAttribute('title') || titleEl.innerText || titleEl.textContent || '').trim()
                    : '';
            }

            if (!artist) {
                var artistEl =
                    document.querySelector('ytmusic-player-bar .byline') ||
                    document.querySelector('ytmusic-player-bar yt-formatted-string.byline') ||
                    document.querySelector('ytmusic-player-bar .subtitle');

                artist = artistEl
                    ? (artistEl.getAttribute('title') || artistEl.innerText || artistEl.textContent || '').trim()
                    : '';
            }

            var artworkUrl = '';
            if (
                navigator.mediaSession &&
                navigator.mediaSession.metadata &&
                navigator.mediaSession.metadata.artwork &&
                navigator.mediaSession.metadata.artwork.length > 0
            ) {
                var artworks = navigator.mediaSession.metadata.artwork;
                artworkUrl = artworks[artworks.length - 1].src || '';
            }

            if (!artworkUrl) {
                var imgEl =
                    document.querySelector('ytmusic-player-bar img.image') ||
                    document.querySelector('.thumbnail-image-wrapper img') ||
                    document.querySelector('#song-image img');

                artworkUrl = imgEl ? imgEl.src : '';
            }

            if (artworkUrl) {
                artworkUrl = artworkUrl
                    .replace(/=w[0-9]+-h[0-9]+[^&]*/, '=w512-h512-l90-rj')
                    .replace(/=s[0-9]+[^&]*/, '=s512');
            }

            var likeBtn =
                document.querySelector('ytmusic-like-button-renderer #button-shape-like button') ||
                document.querySelector('ytmusic-like-button-renderer .like-button button');

            var isLiked = likeBtn
                ? (likeBtn.getAttribute('aria-pressed') === 'true' || likeBtn.classList.contains('active'))
                : false;

            var dislikeBtn =
                document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button') ||
                document.querySelector('ytmusic-like-button-renderer .dislike-button button');

            var isDisliked = dislikeBtn
                ? (dislikeBtn.getAttribute('aria-pressed') === 'true' || dislikeBtn.classList.contains('active'))
                : false;

            var repeatBtn =
                document.querySelector('ytmusic-player-bar .repeat-button') ||
                document.querySelector('ytmusic-player-bar tp-yt-paper-icon-button.repeat-button') ||
                document.querySelector('ytmusic-player-bar [title*="Repeat"]') ||
                document.querySelector('ytmusic-player-bar [title*="Повтор"]') ||
                document.querySelector('ytmusic-player-bar [aria-label*="Repeat"]') ||
                document.querySelector('ytmusic-player-bar [aria-label*="Повтор"]');

            var repeatMode = 0;
            if (repeatBtn) {
                var label = (
                    repeatBtn.getAttribute('aria-label') ||
                    repeatBtn.getAttribute('title') || ''
                ).toLowerCase();
                var html = (repeatBtn.innerHTML || '').toLowerCase();
                var isPressed =
                    repeatBtn.getAttribute('aria-pressed') === 'true' ||
                    repeatBtn.classList.contains('active');

                if (
                    html.includes('repeat_one') ||
                    html.includes('repeat-one') ||
                    label.includes('one') ||
                    label.includes('1') ||
                    label.includes('один') ||
                    label.includes('одну')
                ) {
                    repeatMode = 2;
                } else if (isPressed || label.includes('all') || label.includes('все') || label.includes('всі') || label.includes('alle') || label.includes('tutti')) {
                    repeatMode = 1;
                }
            }

            var queue = [];
            var playlists = [];

            if (isFullSync) {
                var validItems = getQueueItems();
                var activeDomIdx = -1;
                var bestTitleIdx = -1;
                var bestDomSelIdx = -1;

                for (var k = 0; k < validItems.length; k++) {
                    var el = validItems[k];
                    var tEl =
                        el.querySelector('.song-title') ||
                        el.querySelector('.title') ||
                        el.querySelector('yt-formatted-string.title');

                    var tText = tEl ? (tEl.innerText || tEl.textContent || '').trim() : '';
                    if (!tText) continue;

                    var isDomSelected =
                        el.hasAttribute('selected') ||
                        el.classList.contains('selected') ||
                        el.getAttribute('play-button-state') === 'playing' ||
                        el.querySelector('ytmusic-equalizer') !== null;

                    var isTitleMatching = titlesMatch(tText, title);

                    if (isDomSelected && isTitleMatching && activeDomIdx === -1) {
                        activeDomIdx = k;
                    }
                    if (isTitleMatching && bestTitleIdx === -1) {
                        bestTitleIdx = k;
                    }
                    if (isDomSelected && bestDomSelIdx === -1) {
                        bestDomSelIdx = k;
                    }
                }

                if (activeDomIdx === -1) {
                    activeDomIdx = bestTitleIdx !== -1 ? bestTitleIdx : bestDomSelIdx;
                }

                var rawQueue = [];
                var seenMap = {};

                validItems.forEach(function(item, idx) {
                    var qTitleEl =
                        item.querySelector('.song-title') ||
                        item.querySelector('.title') ||
                        item.querySelector('yt-formatted-string.title');

                    var qArtistEl =
                        item.querySelector('.byline') ||
                        item.querySelector('.author') ||
                        item.querySelector('.subtitle') ||
                        item.querySelector('yt-formatted-string.byline');

                    var qTitle = qTitleEl ? (qTitleEl.innerText || qTitleEl.textContent || '').trim() : '';
                    var qArtist = qArtistEl ? (qArtistEl.innerText || qArtistEl.textContent || '').trim() : '';

                    if (!qTitle) return;
                    var dedupeKey = normStr(qTitle);
                    if (!dedupeKey) return;

                    var isCurrentActive = idx === activeDomIdx;

                    if (seenMap.hasOwnProperty(dedupeKey)) {
                        var existingIndex = seenMap[dedupeKey];
                        if (isCurrentActive) {
                            rawQueue[existingIndex].isSelected = true;
                            rawQueue[existingIndex].originalIndex = idx;
                            rawQueue[existingIndex].title = qTitle;
                            if (qArtist) rawQueue[existingIndex].artist = qArtist;
                        }
                        return;
                    }

                    var queueIndex = rawQueue.length;
                    seenMap[dedupeKey] = queueIndex;

                    rawQueue.push({
                        id: 'q_' + queueIndex + '_' + encodeURIComponent(qTitle),
                        originalIndex: idx,
                        title: qTitle,
                        artist: qArtist,
                        isSelected: isCurrentActive
                    });
                });

                var selectedIdx = rawQueue.findIndex(function(item) { return item.isSelected; });
                queue = rawQueue;
                if (selectedIdx > 10) {
                    queue = rawQueue.slice(selectedIdx - 10);
                }

                // Multilingual term filters for system navigation links
                var ignoreTerms = [
                    'главная', 'обзор', 'библиотека', 'настройки', 'подкасты', 'чарты',
                    'home', 'explore', 'library', 'podcasts', 'charts', 'settings',
                    'улучшить', 'upgrade', 'радио', 'radio', 'startseite', 'entdecken',
                    'mediathek', 'inicio', 'explorar', 'biblioteca', 'boletim', 'esplora'
                ];

                var isLibraryPlaylistsPage = window.location.href.includes('/library/playlists');
                var seenPlaylists = {};

                var guideEntries = document.querySelectorAll(
                    'ytmusic-guide-entry-renderer a[href*="list="], ' +
                    '#guide-content a[href*="list="], ' +
                    '#sections a[href*="list="], ' +
                    'tp-yt-paper-item a[href*="list="]'
                );

                guideEntries.forEach(function(link) {
                    var href = link.getAttribute('href');
                    if (!href) return;

                    var listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                    if (!listMatch) return;

                    var listId = listMatch[1];
                    var isPersonalList =
                        (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                        !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');

                    var text = link.innerText ? link.innerText.trim() : '';
                    if (text) text = text.split('\n')[0].trim();

                    var lowerText = text.toLowerCase();
                    var isSystem = ignoreTerms.some(function(term) {
                        return lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade');
                    });

                    if (isPersonalList && text && text.length > 0 && text.length < 60 && !seenPlaylists[listId] && !isSystem) {
                        seenPlaylists[listId] = true;
                        playlists.push({ id: listId, title: text, path: href });
                    }
                });

                var cardItems = document.querySelectorAll(
                    'ytmusic-two-row-item-renderer, ytmusic-responsive-list-item-renderer'
                );

                cardItems.forEach(function(item) {
                    var link = item.querySelector('a[href*="list="]');
                    if (!link) return;

                    var href = link.getAttribute('href');
                    if (!href) return;

                    var listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                    if (!listMatch) return;

                    var listId = listMatch[1];
                    if (seenPlaylists[listId]) return;

                    var isPersonalList =
                        (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                        !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');

                    var badge = item.querySelector('ytmusic-inline-badge-renderer');
                    var isPinned = badge
                        ? ((badge.innerText && (badge.innerText.includes('Закріп') || badge.innerText.includes('Pinned') || badge.innerText.includes('Закреп') || badge.innerText.includes('Angepinnt') || badge.innerText.includes('Fijado'))) ||
                           (badge.innerHTML && (badge.innerHTML.includes('Закріп') || badge.innerHTML.includes('Pinned') || badge.innerHTML.includes('Закреп') || badge.innerHTML.includes('Angepinnt') || badge.innerHTML.includes('Fijado'))))
                        : false;

                    var titleEl =
                        item.querySelector('.title-group .title') ||
                        item.querySelector('.title') ||
                        item.querySelector('yt-formatted-string');

                    var text = titleEl ? (titleEl.innerText || titleEl.textContent || '').trim() : '';
                    if (text) text = text.split('\n')[0].trim();

                    var lowerText = text.toLowerCase();
                    var isSystem = ignoreTerms.some(function(term) {
                        return lowerText === term || lowerText.includes('улучшить') || lowerText.includes('upgrade');
                    });

                    if (isPersonalList && (isPinned || isLibraryPlaylistsPage) && text && text.length > 0 && text.length < 60 && !isSystem) {
                        seenPlaylists[listId] = true;
                        playlists.push({ id: listId, title: text, path: href });
                    }
                });
            }

            // Triple protection check for user authentication state
            var signInBtn =
                document.querySelector('a[href*="ServiceLogin"]') ||
                document.querySelector('ytmusic-sign-in-button-renderer') ||
                document.querySelector('a[href*="accounts.google.com"]') ||
                document.querySelector('.sign-in-link');

            var avatarBtn =
                document.querySelector('#avatar-btn') ||
                document.querySelector('ytmusic-avatar-button') ||
                document.querySelector('img#img[src*="googleusercontent"]') ||
                document.querySelector('tp-yt-paper-icon-button#account-button');

            var hasPlaylistsInDom = (playlists && playlists.length > 0) || (queue && queue.length > 0);

            var isLoggedIn = true;
            if (signInBtn !== null && !hasPlaylistsInDom && avatarBtn === null) {
                isLoggedIn = false;
            } else if (avatarBtn !== null || hasPlaylistsInDom) {
                isLoggedIn = true;
            } else {
                isLoggedIn = (window.lastKnownLoggedIn !== undefined) ? window.lastKnownLoggedIn : true;
            }
            window.lastKnownLoggedIn = isLoggedIn;

            var payload = {
                isLoggedIn: isLoggedIn,
                isPlaying: isPlaying,
                currentTime: currentTime,
                duration: duration,
                title: title,
                artist: artist,
                artworkUrl: artworkUrl,
                isLiked: isLiked,
                isDisliked: isDisliked,
                repeatMode: repeatMode
            };

            if (isFullSync) {
                payload.queue = queue;
                payload.playlists = playlists;
            }

            window.webkit.messageHandlers.ytmBridge.postMessage(payload);
        } catch (error) {}
    }

    setInterval(function() {
        syncYTM(false);
    }, 1800);
    """#
}
