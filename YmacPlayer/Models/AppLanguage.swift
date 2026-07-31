import Foundation

// MARK: - Supported App Languages

/// Represents the list of supported application languages for Ymac Player.
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

    /// The unique identifier corresponding to the language code.
    var id: String { rawValue }

    /// The localized display name of the language in its native form.
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

// MARK: - Localized Strings Helper

/// Provides localized string resources across all supported languages for Ymac Player.
struct LocalizedStrings {
    
    static func pleaseSignIn(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Please sign in"
        case .german: return "Bitte anmelden"
        case .russian: return "Пожалуйста, войдите"
        case .ukrainian: return "Будь ласка, увійдіть"
        case .spanish: return "Inicia sesión"
        case .portuguese: return "Faça login"
        case .italian: return "Per favore, accedi"
        case .french: return "Veuillez vous connecter"
        case .romanian: return "Conectează-te"
        case .polish: return "Zaloguj się"
        }
    }
    
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

    static func playing(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Playing"
        case .german: return "Wiedergabe"
        case .russian: return "Воспроизводится"
        case .ukrainian: return "Відтворюється"
        case .spanish: return "Reproduciendo"
        case .portuguese: return "Reproduzindo"
        case .italian: return "In riproduzione"
        case .french: return "Lecture"
        case .romanian: return "Redare"
        case .polish: return "Odtwarzanie"
        }
    }

    static func paused(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Paused"
        case .german: return "Pausiert"
        case .russian: return "На паузе"
        case .ukrainian: return "На паузі"
        case .spanish: return "En pausa"
        case .portuguese: return "Pausado"
        case .italian: return "In pausa"
        case .french: return "En pause"
        case .romanian: return "Pauză"
        case .polish: return "Wstrzymano"
        }
    }
}
