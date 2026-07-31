//
//  AppLanguage.swift
//  YmacPlayer
//
//  Created by Valentyn Bazavluk on 30.07.26.
//


import SwiftUI
import WebKit
import Combine
import AppKit
import MediaPlayer
import ServiceManagement

// MARK: - Supported App Languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case german = "de"
    case russian = "ru"
    case ukrainian = "uk"
    case spanish = "es"
    case portuguese = "pt"
    case italian = "it"
    case french = "fr"
    case romanian = "ro"
    case polish = "pl"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        case .ukrainian: return "Українська"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .italian: return "Italiano"
        case .french: return "Français"
        case .romanian: return "Română"
        case .polish: return "Polski"
        }
    }
}

// MARK: - Library Filter Categories
enum LibraryFilter: String, CaseIterable {
    case favoritePlaylists = "favoritePlaylists"
    case playlists = "playlists"
}

// MARK: - Localized Strings Helper
struct LocalizedStrings {
    static func selectPlaylist(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Select playlist..."
        case .german: return "Wähle Playlist..."
        case .russian: return "Выберите плейлист..."
        case .ukrainian: return "Оберіть плейлист..."
        case .spanish: return "Seleccionar lista..."
        case .portuguese: return "Selecionar playlist..."
        case .italian: return "Seleziona playlist..."
        case .french: return "Choisir une playlist..."
        case .romanian: return "Selectează playlist..."
        case .polish: return "Wybierz playlistę..."
        }
    }

    static func loadingPlaylists(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Loading..."
        case .german: return "Laden..."
        case .russian: return "Загрузка..."
        case .ukrainian: return "Завантаження..."
        case .spanish: return "Cargando..."
        case .portuguese: return "Carregando..."
        case .italian: return "Caricamento..."
        case .french: return "Chargement..."
        case .romanian: return "Se încarcă..."
        case .polish: return "Ładowanie..."
        }
    }

    static func selectPlaylistPrompt(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Select playlist above"
        case .german: return "Wähle oben eine Playlist"
        case .russian: return "Выберите плейлист вверху"
        case .ukrainian: return "Оберіть плейлист зверху"
        case .spanish: return "Selecciona una lista arriba"
        case .portuguese: return "Selecione uma playlist acima"
        case .italian: return "Seleziona una playlist sopra"
        case .french: return "Choisissez une playlist ci-dessus"
        case .romanian: return "Selectează o listă de mai sus"
        case .polish: return "Wybierz playlistę powyżej"
        }
    }

    static func toggleViewHelp(_ lang: AppLanguage, showFull: Bool) -> String {
        if showFull {
            switch lang {
            case .english: return "Collapse player"
            case .german: return "Player einklappen"
            case .russian: return "Свернуть плеер"
            case .ukrainian: return "Згорнути плеєр"
            case .spanish: return "Contraer reproductor"
            case .portuguese: return "Recolher reproductor"
            case .italian: return "Comprimi lettore"
            case .french: return "Réduire le lecteur"
            case .romanian: return "Restrânge playerul"
            case .polish: return "Zwiń odtwarzacz"
            }
        } else {
            switch lang {
            case .english: return "Open web view (for login)"
            case .german: return "Webansicht öffnen (zum Anmelden)"
            case .russian: return "Открыть веб-версию (для входа)"
            case .ukrainian: return "Відкрити веб-версію (для входу)"
            case .spanish: return "Abrir vista web (para iniciar sesión)"
            case .portuguese: return "Abrir visualização web (para login)"
            case .italian: return "Apri vista web (per accedere)"
            case .french: return "Ouvrir la vue web (connexion)"
            case .romanian: return "Deschide vizualizarea web (pentru conectare)"
            case .polish: return "Otwórz widok sieciowy (do logowania)"
            }
        }
    }

    static func languageMenuTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Language"
        case .german: return "Sprache"
        case .russian: return "Язык"
        case .ukrainian: return "Мова"
        case .spanish: return "Idioma"
        case .portuguese: return "Idioma"
        case .italian: return "Lingua"
        case .french: return "Langue"
        case .romanian: return "Limbă"
        case .polish: return "Język"
        }
    }

    static func libraryMenuTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "My Library"
        case .german: return "Meine Bibliothek"
        case .russian: return "Моя библиотека"
        case .ukrainian: return "Моя бібліотека"
        case .spanish: return "Mi biblioteca"
        case .portuguese: return "Minha biblioteca"
        case .italian: return "La mia biblioteca"
        case .french: return "Ma bibliothèque"
        case .romanian: return "Biblioteca mea"
        case .polish: return "Moja biblioteka"
        }
    }

    static func favoritePlaylistsCategoryTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "My Favorite Playlists"
        case .german: return "Meine Lieblings-Playlists"
        case .russian: return "Мои любимые плейлисты"
        case .ukrainian: return "Мої улюблені плейлисти"
        case .spanish: return "Mis listas favoritas"
        case .portuguese: return "Minhas playlists favoritas"
        case .italian: return "Le mie playlist preferite"
        case .french: return "Mes playlists préférées"
        case .romanian: return "Playlisturile mele favorite"
        case .polish: return "Moje ulubione playlisty"
        }
    }

    static func playlistsCategoryTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Playlists"
        case .german: return "Playlists"
        case .russian: return "Списки воспроизведения"
        case .ukrainian: return "Списки відтворення"
        case .spanish: return "Listas de reproducción"
        case .portuguese: return "Playlists"
        case .italian: return "Playlist"
        case .french: return "Playlists"
        case .romanian: return "Listefixate"
        case .polish: return "Playlisty"
        }
    }

    static func autostartMenuTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Launch at Login"
        case .german: return "Bei Anmeldung starten"
        case .russian: return "Автозапуск при входе"
        case .ukrainian: return "Автозапуск при вході"
        case .spanish: return "Iniciar al iniciar sesión"
        case .portuguese: return "Iniciar no login"
        case .italian: return "Avvia all'accesso"
        case .french: return "Lancer au démarrage"
        case .romanian: return "Lansează la conectare"
        case .polish: return "Uruchamiaj przy logowaniu"
        }
    }

    static func aboutMenuTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "About Ymac Player"
        case .german: return "Über Ymac Player"
        case .russian: return "О программе Ymac Player"
        case .ukrainian: return "Про програму Ymac Player"
        case .spanish: return "Acerca de Ymac Player"
        case .portuguese: return "Sobre o Ymac Player"
        case .italian: return "Informazioni su Ymac Player"
        case .french: return "À propos de Ymac Player"
        case .romanian: return "Despre Ymac Player"
        case .polish: return "O Ymac Player"
        }
    }

    static func quitApp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Quit App"
        case .german: return "App beenden"
        case .russian: return "Завершить программу"
        case .ukrainian: return "Завершити програму"
        case .spanish: return "Salir de la aplicación"
        case .portuguese: return "Sair do aplicativo"
        case .italian: return "Esci dall'applicazione"
        case .french: return "Quitter l'application"
        case .romanian: return "Închide aplicația"
        case .polish: return "Zamknij aplikację"
        }
    }

    static func upNext(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Up Next"
        case .german: return "Nächste Titel"
        case .russian: return "Далее в очереди"
        case .ukrainian: return "Далі в черзі"
        case .spanish: return "A continuación"
        case .portuguese: return "A seguir"
        case .italian: return "In coda"
        case .french: return "À suivre"
        case .romanian: return "Urmează"
        case .polish: return "Następne"
        }
    }

    static func emptyQueue(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Queue is empty"
        case .german: return "Warteschlange leer"
        case .russian: return "Очередь пуста"
        case .ukrainian: return "Черга порожня"
        case .spanish: return "Cola vacía"
        case .portuguese: return "Fila vazia"
        case .italian: return "Coda vuota"
        case .french: return "File d'attente vide"
        case .romanian: return "Coadă goală"
        case .polish: return "Kolejka pusta"
        }
    }
}

// MARK: - Playlist & Queue Models
struct YTMPlaylist: Identifiable, Hashable {
    let id: String
    let title: String
    let path: String
}

struct YTMQueueItem: Identifiable, Hashable {
    let id: String
    let originalIndex: Int
    let title: String
    let artist: String
    let isSelected: Bool
}

// MARK: - Main Player Controller & JS Bridge
@MainActor
class YTMController: NSObject, ObservableObject, WKScriptMessageHandler {
    static let shared = YTMController()
    let webView: WKWebView

    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = "YouTube Music"
    @Published var currentArtist: String = ""
    @Published var artworkUrl: String = ""
    @Published var userPlaylists: [YTMPlaylist] = []
    @Published var queue: [YTMQueueItem] = []
    
    @Published var isLiked: Bool = false
    @Published var isDisliked: Bool = false
    @Published var isShuffle: Bool = false
    @Published var repeatMode: Int = 0 // 0: Off, 1: Repeat All, 2: Repeat One

    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isEditingSlider: Bool = false
    
    @Published var hasSelectedPlaylist: Bool = false
    @Published var currentLanguage: AppLanguage = .english

    // Library Category Settings
    @Published var libraryFilter: LibraryFilter = .favoritePlaylists

    private var lastLoadedArtworkUrl: String = ""
    private var cachedArtworkImage: NSImage? = nil

    override init() {
        if let savedLang = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = lang
        }

        if let savedFilter = UserDefaults.standard.string(forKey: "libraryFilter"),
           let filter = LibraryFilter(rawValue: savedFilter) {
            self.libraryFilter = filter
        }

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        
        super.init()
        
        userContentController.add(self, name: "ytmBridge")
        setupRemoteCommands()

        let scriptSource = #"""
        window.hasTriggeredGuide = false;
        window.hasAutoPausedInitial = false;

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

        function normArtist(str) {
            if (!str) return '';
            return str.toLowerCase()
                .replace(/ - topic/gi, '')
                .replace(/[^a-z0-9а-яіїєґ]/gi, '')
                .trim();
        }

        function titlesMatch(t1, t2) {
            var n1 = normStr(t1);
            var n2 = normStr(t2);
            if (!n1 || !n2) return false;
            if (n1 === n2) return true;
            if (n1.length > 3 && n2.length > 3) {
                if (n1.indexOf(n2) !== -1 || n2.indexOf(n1) !== -1) return true;
            }
            return false;
        }

        function getQueueItems() {
            var queuePanel = document.querySelector('ytmusic-player-queue') || 
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
                var mainContents = document.querySelector('#contents.ytmusic-playlist-video-list-renderer') ||
                                   document.querySelector('#items.ytmusic-playlist-panel-renderer');
                if (mainContents) {
                    elements = mainContents.querySelectorAll('ytmusic-playlist-panel-video-renderer, ytmusic-responsive-list-item-renderer');
                }
            }
            
            if (!elements || elements.length === 0) {
                elements = document.querySelectorAll('ytmusic-player-queue-item');
            }

            var valid = [];
            elements.forEach(function(item) {
                if (item.closest('ytmusic-player-bar') || 
                    item.closest('#player-bar') ||
                    item.closest('ytmusic-playlist-header-renderer') ||
                    item.closest('ytmusic-responsive-header-renderer') ||
                    item.closest('ytmusic-editable-playlist-detail-header-renderer') ||
                    item.closest('ytmusic-detail-header-renderer') ||
                    item.closest('#header') ||
                    item.closest('.header')) {
                    return;
                }
                valid.push(item);
            });
            return valid;
        }

        function syncYTM() {
            try {
                var video = document.querySelector('video');
                var isPlaylistUrl = window.location.href.includes('list=') || window.location.href.includes('browse/');
                
                if (!isPlaylistUrl && !window.hasAutoPausedInitial && video && !video.paused) {
                    video.pause();
                    window.hasAutoPausedInitial = true;
                }

                if (!window.hasTriggeredGuide) {
                    var gBtn = document.querySelector('ytmusic-guide-button button') || 
                               document.querySelector('#guide-button button') || 
                               document.querySelector('tp-yt-paper-icon-button#button');
                    if (gBtn) {
                        gBtn.click();
                        window.hasTriggeredGuide = true;
                        setTimeout(function() { if (gBtn) gBtn.click(); }, 350);
                    }
                }

                var isPlaying = video ? (!video.paused && video.currentTime > 0 && video.readyState > 2) : false;
                var currentTime = video ? video.currentTime : 0;
                var duration = (video && !isNaN(video.duration)) ? video.duration : 0;

                var title = '';
                var artist = '';

                if (navigator.mediaSession && navigator.mediaSession.metadata) {
                    title = navigator.mediaSession.metadata.title || '';
                    artist = navigator.mediaSession.metadata.artist || '';
                }

                if (!title) {
                    var titleEl = document.querySelector('ytmusic-player-bar .title') || 
                                  document.querySelector('ytmusic-player-bar yt-formatted-string.title') ||
                                  document.querySelector('.middle-controls .title');
                    title = titleEl ? (titleEl.getAttribute('title') || titleEl.innerText || titleEl.textContent || '').trim() : '';
                }

                if (!artist) {
                    var artistEl = document.querySelector('ytmusic-player-bar .byline') || 
                                   document.querySelector('ytmusic-player-bar yt-formatted-string.byline') ||
                                   document.querySelector('ytmusic-player-bar .subtitle');
                    artist = artistEl ? (artistEl.getAttribute('title') || artistEl.innerText || artistEl.textContent || '').trim() : '';
                }

                var artworkUrl = '';
                if (navigator.mediaSession && navigator.mediaSession.metadata && navigator.mediaSession.metadata.artwork && navigator.mediaSession.metadata.artwork.length > 0) {
                    var artworks = navigator.mediaSession.metadata.artwork;
                    artworkUrl = artworks[artworks.length - 1].src || '';
                }

                if (!artworkUrl) {
                    var imgEl = document.querySelector('ytmusic-player-bar img.image') || 
                                document.querySelector('.thumbnail-image-wrapper img') ||
                                document.querySelector('#song-image img');
                    artworkUrl = imgEl ? imgEl.src : '';
                }

                if (artworkUrl) {
                    artworkUrl = artworkUrl.replace(/=w[0-9]+-h[0-9]+[^&]*/, '=w512-h512-l90-rj')
                                           .replace(/=s[0-9]+[^&]*/, '=s512');
                }

                var likeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-like button') || 
                              document.querySelector('ytmusic-like-button-renderer .like-button button');
                var isLiked = likeBtn ? (likeBtn.getAttribute('aria-pressed') === 'true' || likeBtn.classList.contains('active')) : false;

                var dislikeBtn = document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button') || 
                                 document.querySelector('ytmusic-like-button-renderer .dislike-button button');
                var isDisliked = dislikeBtn ? (dislikeBtn.getAttribute('aria-pressed') === 'true' || dislikeBtn.classList.contains('active')) : false;

                var repeatBtn = document.querySelector('ytmusic-player-bar .repeat-button') || 
                                document.querySelector('ytmusic-player-bar tp-yt-paper-icon-button.repeat-button') ||
                                document.querySelector('ytmusic-player-bar [title*="Repeat"]') ||
                                document.querySelector('ytmusic-player-bar [title*="Повтор"]') ||
                                document.querySelector('ytmusic-player-bar [aria-label*="Repeat"]') ||
                                document.querySelector('ytmusic-player-bar [aria-label*="Повтор"]');
                var repeatMode = 0;
                if (repeatBtn) {
                    var label = (repeatBtn.getAttribute('aria-label') || repeatBtn.getAttribute('title') || '').toLowerCase();
                    var html = (repeatBtn.innerHTML || '').toLowerCase();
                    var isPressed = repeatBtn.getAttribute('aria-pressed') === 'true' || repeatBtn.classList.contains('active');
                    
                    if (html.includes('repeat_one') || html.includes('repeat-one') || label.includes('one') || label.includes('1') || label.includes('один') || label.includes('одну') || label.includes('трек') || label.includes('композиц')) {
                        repeatMode = 2;
                    } else if (isPressed || label.includes('all') || label.includes('все') || label.includes('всі') || label.includes('alle')) {
                        repeatMode = 1;
                    }
                }

                var validItems = getQueueItems();
                var activeDomIdx = -1;
                var bestTitleIdx = -1;
                var bestDomSelIdx = -1;

                for (var k = 0; k < validItems.length; k++) {
                    var el = validItems[k];
                    var tEl = el.querySelector('.song-title') || el.querySelector('.title') || el.querySelector('yt-formatted-string.title');
                    var tText = tEl ? (tEl.innerText || tEl.textContent || '').trim() : '';
                    if (!tText) continue;

                    var isDomSelected = el.hasAttribute('selected') || 
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
                    activeDomIdx = (bestTitleIdx !== -1) ? bestTitleIdx : bestDomSelIdx;
                }

                var rawQueue = [];
                var seenMap = {};

                validItems.forEach(function(item, idx) {
                    var qTitleEl = item.querySelector('.song-title') || item.querySelector('.title') || item.querySelector('yt-formatted-string.title');
                    var qArtistEl = item.querySelector('.byline') || item.querySelector('.author') || item.querySelector('.subtitle') || item.querySelector('yt-formatted-string.byline');
                    var qTitle = qTitleEl ? (qTitleEl.innerText || qTitleEl.textContent || '').trim() : '';
                    var qArtist = qArtistEl ? (qArtistEl.innerText || qArtistEl.textContent || '').trim() : '';
                    
                    if (!qTitle) return;

                    var dedupeKey = normStr(qTitle);
                    if (!dedupeKey) return;

                    var isCurrentActive = (idx === activeDomIdx);

                    if (seenMap.hasOwnProperty(dedupeKey)) {
                        var existingIndex = seenMap[dedupeKey];
                        if (isCurrentActive) {
                            rawQueue[existingIndex].isSelected = true;
                            rawQueue[existingIndex].originalIndex = idx;
                            rawQueue[existingIndex].title = qTitle;
                            if (qArtist) {
                                rawQueue[existingIndex].artist = qArtist;
                            }
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

                var selectedIdx = rawQueue.findIndex(function(i) { return i.isSelected; });
                var queue = rawQueue;
                if (selectedIdx > 10) {
                    queue = rawQueue.slice(selectedIdx - 10);
                }

                // Strict Personal & Pinned Playlist Parser
                var playlists = [];
                var seen = {};
                var ignoreTerms = ['главная', 'обзор', 'библиотека', 'настройки', 'подкасты', 'чарты', 'home', 'explore', 'library', 'podcasts', 'charts', 'улучшить', 'upgrade', 'радио', 'radio'];
                var isLibraryPlaylistsPage = window.location.href.includes('/library/playlists');

                // 1. Extract from sidebar menu
                var guideEntries = document.querySelectorAll('ytmusic-guide-entry-renderer a[href*="list="], #guide-content a[href*="list="], #sections a[href*="list="], tp-yt-paper-item a[href*="list="]');
                guideEntries.forEach(function(link) {
                    var href = link.getAttribute('href');
                    if (!href) return;
                    
                    var listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                    if (!listMatch) return;
                    var listId = listMatch[1];
                    
                    var isPersonalList = (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                                         !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');
                    
                    var text = link.innerText ? link.innerText.trim() : '';
                    if (text) { text = text.split('\n')[0].trim(); }
                    var lowerText = text.toLowerCase();
                    var isSystem = ignoreTerms.some(function(term) { return lowerText === term || lowerText.includes('улучшить'); });
                    
                    if (isPersonalList && text && text.length > 0 && text.length < 60 && !seen[listId] && !isSystem) {
                        seen[listId] = true;
                        playlists.push({ id: listId, title: text, path: href });
                    }
                });

                // 2. Extract PINNED or Library page playlists
                var cardItems = document.querySelectorAll('ytmusic-two-row-item-renderer, ytmusic-responsive-list-item-renderer');
                cardItems.forEach(function(item) {
                    var link = item.querySelector('a[href*="list="]');
                    if (!link) return;
                    var href = link.getAttribute('href');
                    if (!href) return;
                    
                    var listMatch = href.match(/list=([a-zA-Z0-9_-]+)/);
                    if (!listMatch) return;
                    var listId = listMatch[1];
                    
                    if (seen[listId]) return;
                    
                    var isPersonalList = (href.includes('list=PL') || href.includes('list=LM') || href.includes('list=LL') || href.includes('list=FL')) &&
                                         !href.includes('list=RD') && !href.includes('list=OLAK') && !href.includes('watch?v=');
                    
                    var badge = item.querySelector('ytmusic-inline-badge-renderer');
                    var isPinned = badge ? (
                        (badge.innerText && (badge.innerText.includes('Закріп') || badge.innerText.includes('Pinned') || badge.innerText.includes('Закреп'))) ||
                        (badge.innerHTML && (badge.innerHTML.includes('Закріп') || badge.innerHTML.includes('Pinned') || badge.innerHTML.includes('Закреп')))
                    ) : false;
                    
                    var titleEl = item.querySelector('.title-group .title') || item.querySelector('.title') || item.querySelector('yt-formatted-string');
                    var text = titleEl ? (titleEl.innerText || titleEl.textContent || '').trim() : '';
                    if (text) { text = text.split('\n')[0].trim(); }
                    var lowerText = text.toLowerCase();
                    var isSystem = ignoreTerms.some(function(term) { return lowerText === term || lowerText.includes('улучшить'); });
                    
                    if (isPersonalList && (isPinned || isLibraryPlaylistsPage) && text && text.length > 0 && text.length < 60 && !isSystem) {
                        seen[listId] = true;
                        playlists.push({ id: listId, title: text, path: href });
                    }
                });

                window.webkit.messageHandlers.ytmBridge.postMessage({
                    isPlaying: isPlaying,
                    currentTime: currentTime,
                    duration: duration,
                    title: title,
                    artist: artist,
                    artworkUrl: artworkUrl,
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    repeatMode: repeatMode,
                    queue: queue,
                    playlists: playlists
                });
            } catch(e) {}
        }
        setInterval(syncYTM, 800);
        """#
        
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        if let url = URL(string: "https://music.youtube.com") {
            self.webView.load(URLRequest(url: url))
        }
    }

    nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "ytmBridge", let dict = message.body as? [String: Any] else { return }
        
        Task { @MainActor in
            if let playing = dict["isPlaying"] as? Bool { self.isPlaying = playing }
            
            if !self.isEditingSlider {
                if let cur = dict["currentTime"] as? Double { self.currentTime = cur }
                if let dur = dict["duration"] as? Double { self.duration = dur }
            }
            
            if let title = dict["title"] as? String, !title.isEmpty { self.currentTitle = title }
            if let artist = dict["artist"] as? String { self.currentArtist = artist }
            if let artwork = dict["artworkUrl"] as? String { self.artworkUrl = artwork }
            if let liked = dict["isLiked"] as? Bool { self.isLiked = liked }
            if let disliked = dict["isDisliked"] as? Bool { self.isDisliked = disliked }
            if let rep = dict["repeatMode"] as? Int { self.repeatMode = rep }
            
            if let rawQueue = dict["queue"] as? [[String: Any]] {
                let parsedQueue = rawQueue.compactMap { item -> YTMQueueItem? in
                    guard let itemId = item["id"] as? String,
                          let origIdx = item["originalIndex"] as? Int,
                          let t = item["title"] as? String, !t.isEmpty else { return nil }
                    let a = item["artist"] as? String ?? ""
                    let sel = item["isSelected"] as? Bool ?? false
                    return YTMQueueItem(id: itemId, originalIndex: origIdx, title: t, artist: a, isSelected: sel)
                }
                if parsedQueue != self.queue {
                    self.queue = parsedQueue
                }
            }

            if let rawPlaylists = dict["playlists"] as? [[String: String]] {
                let parsed = rawPlaylists.compactMap { item -> YTMPlaylist? in
                    guard let t = item["title"], let p = item["path"], let id = item["id"] else { return nil }
                    return YTMPlaylist(id: id, title: t, path: p)
                }

                if !parsed.isEmpty && parsed != self.userPlaylists {
                    self.userPlaylists = parsed
                }
            }

            self.updateNowPlayingInfo()
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlay() }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.nextTrack() }
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previousTrack() }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in
                self?.seekTo(event.positionTime)
            }
            return .success
        }
    }

    func updateNowPlayingInfo() {
        guard hasSelectedPlaylist, !currentTitle.isEmpty, currentTitle != "YouTube Music" else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = currentTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = currentArtist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if lastLoadedArtworkUrl == artworkUrl, let image = cachedArtworkImage {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else if let url = URL(string: artworkUrl), !artworkUrl.isEmpty {
            lastLoadedArtworkUrl = artworkUrl
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = NSImage(data: data) {
                    self.cachedArtworkImage = image
                    var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    updatedInfo[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                }
            }
        } else {
            cachedArtworkImage = nil
            lastLoadedArtworkUrl = ""
            nowPlayingInfo[MPMediaItemPropertyArtwork] = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func setLanguage(_ lang: AppLanguage) {
        self.currentLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "appLanguage")
    }

    func setLibraryFilter(_ filter: LibraryFilter) {
        self.libraryFilter = filter
        UserDefaults.standard.set(filter.rawValue, forKey: "libraryFilter")
        
        // Reset player & playlist selection state actively
        self.hasSelectedPlaylist = false
        self.isShuffle = false
        self.repeatMode = 0
        self.isPlaying = false
        self.currentTitle = "YouTube Music"
        self.currentArtist = ""
        self.artworkUrl = ""
        self.queue = []
        self.userPlaylists = []
        self.cachedArtworkImage = nil
        self.lastLoadedArtworkUrl = ""
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        runJS("var v = document.querySelector('video'); if(v) { v.pause(); } window.hasAutoPausedInitial = false;")

        let targetUrl: String
        switch filter {
        case .favoritePlaylists: targetUrl = "https://music.youtube.com"
        case .playlists: targetUrl = "https://music.youtube.com/library/playlists"
        }
        
        if let url = URL(string: targetUrl) {
            webView.load(URLRequest(url: url))
        }
    }

    func runJS(_ script: String) {
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func resetPlaylistSelection() {
        self.hasSelectedPlaylist = false
        self.isShuffle = false
        self.repeatMode = 0
        self.isPlaying = false
        self.currentTitle = "YouTube Music"
        self.currentArtist = ""
        self.artworkUrl = ""
        self.queue = []
        self.cachedArtworkImage = nil
        self.lastLoadedArtworkUrl = ""
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        runJS("var v = document.querySelector('video'); if(v) { v.pause(); } window.hasAutoPausedInitial = false;")
        if let url = URL(string: "https://music.youtube.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func togglePlay() {
        guard hasSelectedPlaylist else { return }
        runJS("var v = document.querySelector('video'); if(v) { v.paused ? v.play() : v.pause(); } else { document.querySelector('#play-pause-button')?.click(); }")
    }
    
    func nextTrack() {
        guard hasSelectedPlaylist else { return }
        runJS("document.querySelector('.next-button')?.click()")
    }
    
    func previousTrack() {
        guard hasSelectedPlaylist else { return }
        runJS("document.querySelector('.previous-button')?.click()")
    }
    
    func playQueueItem(at originalIndex: Int) {
        guard hasSelectedPlaylist else { return }
        runJS(#"""
        (function() {
            var validItems = getQueueItems();
            if (validItems && validItems[\#(originalIndex)]) {
                var item = validItems[\#(originalIndex)];
                var target = item.querySelector('ytmusic-play-button-renderer') ||
                             item.querySelector('#play-button') ||
                             item.querySelector('.play-button') ||
                             item.querySelector('a') ||
                             item.querySelector('.title') || item;
                
                var btn = target.querySelector('button') || target;
                btn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
                if (btn.click) { btn.click(); }
            }
        })();
        """#)
    }

    func likeTrack() {
        guard hasSelectedPlaylist else { return }
        runJS("document.querySelector('ytmusic-like-button-renderer #button-shape-like button')?.click()")
    }
    
    func dislikeTrack() {
        guard hasSelectedPlaylist else { return }
        runJS("document.querySelector('ytmusic-like-button-renderer #button-shape-dislike button')?.click()")
    }

    func toggleShuffle() {
        guard hasSelectedPlaylist else { return }
        self.isShuffle.toggle()
        
        runJS(#"""
        (function() {
            var s = document.querySelector('ytmusic-player-bar .shuffle-button') || 
                    document.querySelector('ytmusic-player-bar tp-yt-paper-icon-button.shuffle-button') ||
                    document.querySelector('ytmusic-player-bar [title*="Shuffle"]') ||
                    document.querySelector('ytmusic-player-bar [title*="Перемеша"]') ||
                    document.querySelector('ytmusic-player-bar [title*="Переміша"]') ||
                    document.querySelector('.shuffle-button');
            if (s) {
                var btn = s.querySelector('button') || s.querySelector('#button') || s;
                btn.click();
            }
        })();
        """#)
    }

    func toggleRepeat() {
        guard hasSelectedPlaylist else { return }
        
        self.repeatMode = (self.repeatMode + 1) % 3
        
        runJS(#"""
        (function() {
            var r = document.querySelector('ytmusic-player-bar .repeat-button') || 
                    document.querySelector('ytmusic-player-bar tp-yt-paper-icon-button.repeat-button') ||
                    document.querySelector('ytmusic-player-bar [title*="Repeat"]') ||
                    document.querySelector('ytmusic-player-bar [title*="Повтор"]') ||
                    document.querySelector('ytmusic-player-bar [aria-label*="Repeat"]') ||
                    document.querySelector('ytmusic-player-bar [aria-label*="Повтор"]');
            if (r) {
                var btn = r.querySelector('button') || r.querySelector('#button') || r;
                btn.click();
            }
        })();
        """#)
    }

    func seekTo(_ time: Double) {
        guard hasSelectedPlaylist else { return }
        self.currentTime = time
        runJS("var v = document.querySelector('video'); if(v) { v.currentTime = \(time); }")
        updateNowPlayingInfo()
    }

    func openPlaylistById(_ listId: String) {
        if listId.isEmpty {
            resetPlaylistSelection()
            return
        }
        
        self.hasSelectedPlaylist = true
        self.isShuffle = false
        
        // FIX: Route ALL playlists (including Liked Music 'LM') to watch?list=ID
        let targetUrl = "https://music.youtube.com/watch?list=\(listId)"

        if let url = URL(string: targetUrl) {
            webView.load(URLRequest(url: url))
        }
    }
}

// MARK: - Web View Wrapper for SwiftUI
struct HiddenWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        return YTMController.shared.webView
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

// MARK: - Menu Bar Extra Delegate (Handles Left/Right Clicks)
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 390)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MainWidgetView().environmentObject(YTMController.shared)
        )
        self.popover = popover

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Ymac Player")
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let controller = YTMController.shared
            let currentLang = controller.currentLanguage

            let menu = NSMenu()
            
            // 1. Language Selection Submenu
            let langSubmenu = NSMenu()
            for lang in AppLanguage.allCases {
                let item = NSMenuItem(
                    title: lang.title,
                    action: #selector(changeLanguage(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = lang
                if lang == currentLang {
                    item.state = .on
                }
                langSubmenu.addItem(item)
            }
            
            let langMenuItem = NSMenuItem(
                title: LocalizedStrings.languageMenuTitle(currentLang),
                action: nil,
                keyEquivalent: ""
            )
            langMenuItem.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
            langMenuItem.submenu = langSubmenu
            menu.addItem(langMenuItem)

            menu.addItem(NSMenuItem.separator())

            // 2. Library Submenu ("Моя бібліотека")
            let librarySubmenu = NSMenu()

            let favPlaylistsItem = NSMenuItem(
                title: LocalizedStrings.favoritePlaylistsCategoryTitle(currentLang),
                action: #selector(selectFavoritePlaylistsCategory(_:)),
                keyEquivalent: ""
            )
            favPlaylistsItem.target = self
            favPlaylistsItem.state = (controller.libraryFilter == .favoritePlaylists) ? .on : .off
            librarySubmenu.addItem(favPlaylistsItem)

            let playlistsCatItem = NSMenuItem(
                title: LocalizedStrings.playlistsCategoryTitle(currentLang),
                action: #selector(selectPlaylistsCategory(_:)),
                keyEquivalent: ""
            )
            playlistsCatItem.target = self
            playlistsCatItem.state = (controller.libraryFilter == .playlists) ? .on : .off
            librarySubmenu.addItem(playlistsCatItem)

            let libraryMenuItem = NSMenuItem(
                title: LocalizedStrings.libraryMenuTitle(currentLang),
                action: nil,
                keyEquivalent: ""
            )
            libraryMenuItem.image = NSImage(systemSymbolName: "building.columns", accessibilityDescription: nil)
            libraryMenuItem.submenu = librarySubmenu
            menu.addItem(libraryMenuItem)

            menu.addItem(NSMenuItem.separator())

            // 3. Launch at Login Item
            let autostartItem = NSMenuItem(
                title: LocalizedStrings.autostartMenuTitle(currentLang),
                action: #selector(toggleAutostart(_:)),
                keyEquivalent: ""
            )
            autostartItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
            autostartItem.target = self
            if #available(macOS 13.0, *) {
                autostartItem.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
            }
            menu.addItem(autostartItem)

            menu.addItem(NSMenuItem.separator())

            // 4. About App Action
            let aboutItem = NSMenuItem(
                title: LocalizedStrings.aboutMenuTitle(currentLang),
                action: #selector(showAboutWindow),
                keyEquivalent: ""
            )
            aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
            aboutItem.target = self
            menu.addItem(aboutItem)

            menu.addItem(NSMenuItem.separator())

            // 5. Quit Application Item
            let quitItem = NSMenuItem(
                title: LocalizedStrings.quitApp(currentLang),
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)

            statusItem.popUpMenu(menu)
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                if let button = statusItem.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
    }

    @objc func changeLanguage(_ sender: NSMenuItem) {
        if let lang = sender.representedObject as? AppLanguage {
            YTMController.shared.setLanguage(lang)
        }
    }

    @objc func selectFavoritePlaylistsCategory(_ sender: NSMenuItem) {
        YTMController.shared.setLibraryFilter(.favoritePlaylists)
    }

    @objc func selectPlaylistsCategory(_ sender: NSMenuItem) {
        YTMController.shared.setLibraryFilter(.playlists)
    }

    @objc func toggleAutostart(_ sender: NSMenuItem) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Failed to toggle autostart: \(error)")
            }
        }
    }

    @objc func showAboutWindow() {
        let alert = NSAlert()
        alert.messageText = "Ymac Player"
        alert.informativeText = "Version 1.0.0\n\nA lightweight, status bar music player for YouTube Music on macOS."
        alert.alertStyle = .informational
        alert.icon = NSImage(systemSymbolName: "music.note.house.fill", accessibilityDescription: nil)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Application Entry Point
@main
struct YTMPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - Main Widget View
struct MainWidgetView: View {
    @EnvironmentObject var controller: YTMController
    @State private var selectedPlaylistId = ""
    @State private var showFullBrowser = false
    @State private var showQueuePopover = false

    var body: some View {
        VStack(spacing: 10) {
            // TOP HEADER: App Title + Playlist Picker
            HStack(spacing: 6) {
                Text("Ymac Player")
                    .font(.system(size: 13, weight: .bold))
                
                Spacer()

                Picker("", selection: $selectedPlaylistId) {
                    Text(controller.userPlaylists.isEmpty 
                         ? LocalizedStrings.loadingPlaylists(controller.currentLanguage) 
                         : LocalizedStrings.selectPlaylist(controller.currentLanguage)).tag("")
                    ForEach(controller.userPlaylists) { pl in
                        Text(pl.title).tag(pl.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: 165)
                .onChange(of: selectedPlaylistId) { oldValue, newId in
                    if newId.isEmpty {
                        controller.resetPlaylistSelection()
                    } else {
                        controller.openPlaylistById(newId)
                    }
                }

                Button(action: { showFullBrowser.toggle() }) {
                    Image(systemName: showFullBrowser ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.toggleViewHelp(controller.currentLanguage, showFull: showFullBrowser))
            }

            ZStack {
                if showFullBrowser {
                    HiddenWebView()
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 10) {
                        HiddenWebView()
                            .frame(width: 1, height: 1)
                            .opacity(0.01)

                        ZStack(alignment: .bottom) {
                            Group {
                                if controller.hasSelectedPlaylist, let url = URL(string: controller.artworkUrl), !controller.artworkUrl.isEmpty {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } else {
                                            Color.gray.opacity(0.2)
                                        }
                                    }
                                } else {
                                    VStack {
                                        Image(systemName: "music.note.list")
                                            .font(.system(size: 55))
                                            .foregroundColor(.secondary)
                                            .offset(y: -35)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.gray.opacity(0.15))
                                }
                            }
                            .frame(width: 260, height: 260)
                            .cornerRadius(14)
                            .clipped()

                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .mask(
                                        LinearGradient(
                                            colors: [.clear, .black.opacity(0.85), .black],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 160)
                            }
                            .frame(width: 260, height: 260)
                            .cornerRadius(14)

                            VStack(spacing: 8) {
                                VStack(spacing: 2) {
                                    if !controller.hasSelectedPlaylist {
                                        Text(LocalizedStrings.selectPlaylistPrompt(controller.currentLanguage))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
                                            .multilineTextAlignment(.center)
                                    } else if !controller.currentTitle.isEmpty && controller.currentTitle != "YouTube Music" {
                                        Text("\(controller.currentTitle)\(controller.currentArtist.isEmpty ? "" : " — " + controller.currentArtist)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .shadow(color: .black.opacity(0.9), radius: 2, x: 0, y: 1)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    } else {
                                        Text(LocalizedStrings.loadingPlaylists(controller.currentLanguage))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(1)
                                    }
                                }

                                VStack(spacing: 1) {
                                    Slider(value: Binding(
                                        get: { controller.currentTime },
                                        set: { newValue in controller.currentTime = newValue }
                                    ), in: 0...max(controller.duration, 1)) { editing in
                                        controller.isEditingSlider = editing
                                        if !editing { controller.seekTo(controller.currentTime) }
                                    }
                                    .tint(.red)
                                    .disabled(!controller.hasSelectedPlaylist)

                                    HStack {
                                        Text(formatTime(controller.currentTime))
                                        Spacer()
                                        Text(formatTime(controller.duration))
                                    }
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.7), radius: 1, x: 0, y: 1)
                                }

                                ZStack {
                                    HStack(spacing: 28) {
                                        Button(action: { controller.previousTrack() }) {
                                            Image(systemName: "backward.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.8), radius: 2)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: { controller.togglePlay() }) {
                                            Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 38))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.8), radius: 2)
                                        }
                                        .buttonStyle(.plain)

                                        Button(action: { controller.nextTrack() }) {
                                            Image(systemName: "forward.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.8), radius: 2)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    HStack {
                                        Spacer()
                                        Button(action: { showQueuePopover.toggle() }) {
                                            Image(systemName: "list.bullet")
                                                .font(.title3)
                                                .foregroundColor(showQueuePopover ? .blue : .white)
                                                .shadow(color: .black.opacity(0.8), radius: 2)
                                        }
                                        .buttonStyle(.plain)
                                        .help(LocalizedStrings.upNext(controller.currentLanguage))
                                        .popover(isPresented: $showQueuePopover, arrowEdge: .top) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(LocalizedStrings.upNext(controller.currentLanguage))
                                                    .font(.caption.bold())
                                                    .padding(.horizontal, 8)
                                                    .padding(.top, 8)
                                                
                                                Divider()

                                                if controller.queue.isEmpty {
                                                    Text(LocalizedStrings.emptyQueue(controller.currentLanguage))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(12)
                                                } else {
                                                    ScrollViewReader { proxy in
                                                        ScrollView {
                                                            VStack(alignment: .leading, spacing: 4) {
                                                                ForEach(controller.queue) { track in
                                                                    Button(action: {
                                                                        controller.playQueueItem(at: track.originalIndex)
                                                                        showQueuePopover = false
                                                                    }) {
                                                                        HStack(spacing: 6) {
                                                                            if track.isSelected {
                                                                                Image(systemName: "play.fill")
                                                                                    .font(.system(size: 9))
                                                                                    .foregroundColor(.blue)
                                                                                    .frame(width: 12)
                                                                            } else {
                                                                                Circle()
                                                                                    .fill(Color.secondary.opacity(0.3))
                                                                                    .frame(width: 4, height: 4)
                                                                                    .frame(width: 12)
                                                                            }
                                                                            
                                                                            VStack(alignment: .leading, spacing: 1) {
                                                                                Text(track.title)
                                                                                    .font(.system(size: 11, weight: track.isSelected ? .bold : .medium))
                                                                                    .foregroundColor(track.isSelected ? .blue : .primary)
                                                                                    .lineLimit(1)
                                                                                
                                                                                if !track.artist.isEmpty {
                                                                                    Text(track.artist)
                                                                                        .font(.system(size: 9))
                                                                                        .foregroundColor(.secondary)
                                                                                        .lineLimit(1)
                                                                                }
                                                                            }
                                                                            Spacer(minLength: 0)
                                                                        }
                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                        .padding(.vertical, 4)
                                                                        .padding(.horizontal, 6)
                                                                        .background(track.isSelected ? Color.blue.opacity(0.12) : Color.clear)
                                                                        .contentShape(Rectangle())
                                                                        .cornerRadius(4)
                                                                    }
                                                                    .buttonStyle(.plain)
                                                                    .id(track.id)
                                                                }
                                                            }
                                                            .padding(.horizontal, 6)
                                                        }
                                                        .frame(width: 240, height: 210)
                                                        .onAppear {
                                                            if let selectedTrack = controller.queue.first(where: { $0.isSelected }) {
                                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                                    withAnimation {
                                                                        proxy.scrollTo(selectedTrack.id, anchor: .center)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .onChange(of: controller.queue) { _, newQueue in
                                                            if let selectedTrack = newQueue.first(where: { $0.isSelected }) {
                                                                withAnimation {
                                                                    proxy.scrollTo(selectedTrack.id, anchor: .center)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(6)
                                        }
                                    }
                                }
                                .disabled(!controller.hasSelectedPlaylist)
                                .opacity(controller.hasSelectedPlaylist ? 1.0 : 0.4)
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                        }
                        .frame(width: 260, height: 260)

                        Divider()

                        HStack {
                            Spacer()
                            
                            Button(action: { controller.likeTrack() }) {
                                Image(systemName: controller.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.title2)
                                    .foregroundColor(controller.isLiked ? .blue : .primary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: { controller.toggleShuffle() }) {
                                Image(systemName: "shuffle")
                                    .font(.title2)
                                    .foregroundColor(controller.isShuffle ? .blue : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(controller.isShuffle ? Color.blue.opacity(0.18) : Color.clear)
                                    .clipShape(Circle())
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: { controller.toggleRepeat() }) {
                                Image(systemName: controller.repeatMode == 2 ? "repeat.1" : "repeat")
                                    .font(.title2)
                                    .foregroundColor(controller.repeatMode > 0 ? .blue : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(controller.repeatMode > 0 ? Color.blue.opacity(0.18) : Color.clear)
                                    .clipShape(Circle())
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: { controller.dislikeTrack() }) {
                                Image(systemName: controller.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.title2)
                                    .foregroundColor(controller.isDisliked ? .red : .primary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .disabled(!controller.hasSelectedPlaylist)
                        .opacity(controller.hasSelectedPlaylist ? 1.0 : 0.4)
                    }
                }
            }
        }
        .padding(12)
        .onChange(of: controller.libraryFilter) { _, _ in
            selectedPlaylistId = ""
        }
    }

    func formatTime(_ timeInSeconds: Double) -> String {
        guard !timeInSeconds.isNaN && !timeInSeconds.isInfinite else { return "0:00" }
        let totalSeconds = Int(timeInSeconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}