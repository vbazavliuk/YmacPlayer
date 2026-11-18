import Foundation

// MARK: - Supported App Languages

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
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

    public var id: String { rawValue }

    public var title: String {
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

public struct LocalizedStrings {

    public static func pleaseSignIn(_ lang: AppLanguage) -> String {
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

    public static func selectPlaylist(_ lang: AppLanguage) -> String {
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

    public static func loadingPlaylists(_ lang: AppLanguage) -> String {
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

    public static func selectPlaylistPrompt(_ lang: AppLanguage) -> String {
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

    public static func toggleViewHelp(_ lang: AppLanguage, showFull: Bool) -> String {
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

    public static func languageMenuTitle(_ lang: AppLanguage) -> String {
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

    public static func libraryMenuTitle(_ lang: AppLanguage) -> String {
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

    public static func favoritePlaylistsCategoryTitle(_ lang: AppLanguage) -> String {
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

    public static func playlistsCategoryTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Playlists"
        case .german: return "Playlists"
        case .russian: return "Списки воспроизведения"
        case .ukrainian: return "Списки відтворення"
        case .spanish: return "Listas de reproducción"
        case .portuguese: return "Playlists"
        case .italian: return "Playlist"
        case .french: return "Playlists"
        case .romanian: return "Liste fixate"
        case .polish: return "Playlisty"
        }
    }

    public static func autostartMenuTitle(_ lang: AppLanguage) -> String {
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

    public static func aboutMenuTitle(_ lang: AppLanguage) -> String {
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

    public static func quitApp(_ lang: AppLanguage) -> String {
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

    public static func upNext(_ lang: AppLanguage) -> String {
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

    public static func emptyQueue(_ lang: AppLanguage) -> String {
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

    public static func playing(_ lang: AppLanguage) -> String {
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

    public static func paused(_ lang: AppLanguage) -> String {
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

    public static func launchPlayer(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Launch Player"
        case .german: return "Player starten"
        case .russian: return "Запустить плеер"
        case .ukrainian: return "Запустити плеєр"
        case .spanish: return "Iniciar reproductor"
        case .portuguese: return "Iniciar player"
        case .italian: return "Avvia player"
        case .french: return "Lancer le lecteur"
        case .romanian: return "Pornește playerul"
        case .polish: return "Uruchom odtwarzacz"
        }
    }

    public static func appNotRunning(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Player is not running"
        case .german: return "Player läuft nicht"
        case .russian: return "Плеер закрыт"
        case .ukrainian: return "Плеєр закрито"
        case .spanish: return "El reproductor no se está ejecutando"
        case .portuguese: return "O player não está em execução"
        case .italian: return "Il player non è in esecuzione"
        case .french: return "Le lecteur n'est pas lancé"
        case .romanian: return "Playerul nu rulează"
        case .polish: return "Odtwarzacz jest wyłączony"
        }
    }

    public static func backButton(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Back"
        case .german: return "Zurück"
        case .russian: return "Назад"
        case .ukrainian: return "Назад"
        case .spanish: return "Atrás"
        case .portuguese: return "Voltar"
        case .italian: return "Indietro"
        case .french: return "Retour"
        case .romanian: return "Înapoi"
        case .polish: return "Wstecz"
        }
    }

    public static func loginButton(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Login"
        case .german: return "Anmelden"
        case .russian: return "Войти"
        case .ukrainian: return "Увійти"
        case .spanish: return "Iniciar sesión"
        case .portuguese: return "Entrar"
        case .italian: return "Accedi"
        case .french: return "Connexion"
        case .romanian: return "Conectare"
        case .polish: return "Zaloguj"
        }
    }

    public static func shuffleHelp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Shuffle"
        case .german: return "Zufallswiedergabe"
        case .russian: return "Перемешать"
        case .ukrainian: return "Перемішати"
        case .spanish: return "Aleatorio"
        case .portuguese: return "Aleatório"
        case .italian: return "Riproduzione casuale"
        case .french: return "Lecture aléatoire"
        case .romanian: return "Redare aleatorie"
        case .polish: return "Losowo"
        }
    }

    public static func repeatHelp(_ lang: AppLanguage, mode: Int) -> String {
        switch mode {
        case 2:
            switch lang {
            case .english: return "Repeat one"
            case .german: return "Titel wiederholen"
            case .russian: return "Повтор одного трека"
            case .ukrainian: return "Повтор одного треку"
            case .spanish: return "Repetir una"
            case .portuguese: return "Repetir uma"
            case .italian: return "Ripeti uno"
            case .french: return "Répéter un titre"
            case .romanian: return "Repetă o piesă"
            case .polish: return "Powtarzaj jeden"
            }
        case 1:
            switch lang {
            case .english: return "Repeat all"
            case .german: return "Alle wiederholen"
            case .russian: return "Повтор всех"
            case .ukrainian: return "Повтор усіх"
            case .spanish: return "Repetir todo"
            case .portuguese: return "Repetir tudo"
            case .italian: return "Ripeti tutto"
            case .french: return "Tout répéter"
            case .romanian: return "Repetă tot"
            case .polish: return "Powtarzaj wszystko"
            }
        default:
            switch lang {
            case .english: return "Repeat off"
            case .german: return "Wiederholung aus"
            case .russian: return "Повтор выключен"
            case .ukrainian: return "Повтор вимкнено"
            case .spanish: return "Repetir desactivado"
            case .portuguese: return "Repetição desativada"
            case .italian: return "Ripetizione disattivata"
            case .french: return "Répétition désactivée"
            case .romanian: return "Repetare oprită"
            case .polish: return "Powtarzanie wyłączone"
            }
        }
    }

    public static func likeHelp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Like"
        case .german: return "Gefällt mir"
        case .russian: return "Нравится"
        case .ukrainian: return "Подобається"
        case .spanish: return "Me gusta"
        case .portuguese: return "Gostei"
        case .italian: return "Mi piace"
        case .french: return "J'aime"
        case .romanian: return "Îmi place"
        case .polish: return "Lubię to"
        }
    }

    public static func dislikeHelp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Dislike"
        case .german: return "Gefällt mir nicht"
        case .russian: return "Не нравится"
        case .ukrainian: return "Не подобається"
        case .spanish: return "No me gusta"
        case .portuguese: return "Não gostei"
        case .italian: return "Non mi piace"
        case .french: return "Je n'aime pas"
        case .romanian: return "Nu îmi place"
        case .polish: return "Nie lubię"
        }
    }

    public static func queueHelp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Up Next Queue"
        case .german: return "Warteschlange"
        case .russian: return "Очередь воспроизведения"
        case .ukrainian: return "Черга відтворення"
        case .spanish: return "Cola de reproducción"
        case .portuguese: return "Fila de reprodução"
        case .italian: return "Coda di riproduzione"
        case .french: return "File d'attente"
        case .romanian: return "Coadă de redare"
        case .polish: return "Kolejka odtwarzania"
        }
    }

    public static func aboutDescription(_ lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return """
            Version 1.0.0

            A lightweight, background-native macOS status bar player and desktop widget for YouTube Music.

            Key Features:
            • Menu Bar Popover: Full player controls, track seeker, and queue viewer.
            • Interactive Desktop Widgets: Control playback and switch playlists directly from macOS Widgets via AppIntents.
            • System Media Integration: Full support for Control Center, Now Playing metadata, and media keys.
            • Multi-Language Support: Available in 10 languages with real-time UI language switching.
            • Background Web Engine: Runs in a dedicated background container to ensure uninterrupted audio playback.

            Built with SwiftUI, WebKit, WidgetKit, and AppIntents.
            """
        case .german:
            return """
            Version 1.0.0

            Ein schlanker, nativer macOS-Menüleisten-Player und Desktop-Widget für YouTube Music.

            Hauptfunktionen:
            • Menüleisten-Popover: Vollständige Wiedergabesteuerung, Titelfortschritt und Warteschlangenansicht.
            • Interaktive Desktop-Widgets: Wiedergabe steuern und Playlists direkt über macOS-Widgets mit AppIntents wechseln.
            • System-Medienintegration: Volle Unterstützung für Kontrollzentrum, „Aktuelle Wiedergabe“-Metadaten und Medientasten.
            • Mehrsprachige Oberfläche: Verfügbar in 10 Sprachen mit sofortigem Sprachwechsel.
            • Web-Engine im Hintergrund: Läuft in einem eigenen Hintergrund-Container für unterbrechungsfreie Audiowiedergabe.

            Entwickelt mit SwiftUI, WebKit, WidgetKit und AppIntents.
            """
        case .russian:
            return """
            Версия 1.0.0

            Лёгкий нативный плеер для строки меню macOS и интерактивный виджет рабочего стола для YouTube Music.

            Основные возможности:
            • Меню в строке состояния: полное управление воспроизведением, перемотка и просмотр очереди.
            • Интерактивные виджеты: управление воспроизведением и переключение плейлистов прямо из виджетов macOS через AppIntents.
            • Интеграция с системой: полная поддержка Пункта управления, метаданных «Сейчас исполняется» и медиа-клавиш.
            • Поддержка 10 языков: мгновенное переключение языка интерфейса в реальном времени.
            • Фоновый веб-движок: работает в отдельном фоновом контейнере для непрерывного воспроизведения звука.

            Создано с помощью SwiftUI, WebKit, WidgetKit и AppIntents.
            """
        case .ukrainian:
            return """
            Версія 1.0.0

            Легкий нативний плеєр для панелі меню macOS та інтерактивний віджет робочого столу для YouTube Music.

            Основні можливості:
            • Поповер у панелі меню: повне керування відтворенням, перемотування треку та перегляд черги.
            • Інтерактивні віджети: керуйте відтворенням і перемикайте плейлисти безпосередньо з віджетів macOS через AppIntents.
            • Системна інтеграція медіа: повна підтримка Центру керування, метаданих «Зараз грає» та медіаклавіш.
            • Багатомовність: підтримка 10 мов із миттєвим перемиканням інтерфейсу.
            • Фоновий вебрушій: працює в окремому фоновому контейнері для безперервного відтворення аудіо.

            Створено за допомогою SwiftUI, WebKit, WidgetKit та AppIntents.
            """
        case .spanish:
            return """
            Versión 1.0.0

            Un reproductor ligero y nativo para la barra de menú de macOS y widget de escritorio para YouTube Music.

            Funciones principales:
            • Ventana en la barra de menú: controles completos de reproducción, barra de progreso y cola de reproducción.
            • Widgets interactivos: controla la reproducción y cambia de lista directamente desde los widgets de macOS con AppIntents.
            • Integración multimedia del sistema: compatibilidad total con el Centro de control, metadatos de En reproducción y teclas multimedia.
            • Soporte multilingüe: disponible en 10 idiomas con cambio instantáneo de interfaz.
            • Motor web en segundo plano: se ejecuta en un contenedor dedicado para garantizar una reproducción de audio continua.

            Desarrollado con SwiftUI, WebKit, WidgetKit y AppIntents.
            """
        case .portuguese:
            return """
            Versão 1.0.0

            Um reprodutor leve e nativo na barra de menus do macOS com widget de área de trabalho para o YouTube Music.

            Principais recursos:
            • Popover na barra de menus: controles completos de reprodução, barra de progresso e visualização da fila.
            • Widgets interativos: controle a reprodução e alterne playlists diretamente pelos widgets do macOS via AppIntents.
            • Integração de mídia do sistema: suporte completo à Central de Controle, metadados de Reproduzindo Agora e teclas de mídia.
            • Suporte multilíngue: disponível em 10 idiomas com troca instantânea na interface.
            • Motor web em segundo plano: executa em um contêiner dedicado para garantir reprodução contínua de áudio.

            Desenvolvido com SwiftUI, WebKit, WidgetKit e AppIntents.
            """
        case .italian:
            return """
            Versione 1.0.0

            Un lettore leggero e nativo per la barra dei menu di macOS con widget desktop per YouTube Music.

            Funzionalità principali:
            • Popover nella barra dei menu: controlli completi di riproduzione, barra di avanzamento e visualizzazione della coda.
            • Widget interattivi: controlla la riproduzione e cambia playlist direttamente dai widget di macOS tramite AppIntents.
            • Integrazione multimediale di sistema: supporto completo per Centro di controllo, metadati In riproduzione e tasti multimediali.
            • Supporto multilingue: disponibile in 10 lingue con cambio immediato dell'interfaccia.
            • Motore web in background: funziona in un contenitore dedicato per garantire una riproduzione audio ininterrotta.

            Sviluppato con SwiftUI, WebKit, WidgetKit e AppIntents.
            """
        case .french:
            return """
            Version 1.0.0

            Un lecteur léger et natif pour la barre des menus macOS avec widget de bureau pour YouTube Music.

            Fonctionnalités principales :
            • Fenêtre dans la barre des menus : contrôles complets de lecture, barre de progression et file d'attente.
            • Widgets interactifs : contrôlez la lecture et changez de playlist directement depuis les widgets macOS via AppIntents.
            • Intégration multimédia système : prise en charge complète du Centre de contrôle, des métadonnées À l'écoute et des touches multimédias.
            • Support multilingue : disponible en 10 langues avec changement instantané de l'interface.
            • Moteur web en arrière-plan : s'exécute dans un conteneur dédié pour assurer une lecture audio ininterrompue.

            Conçu avec SwiftUI, WebKit, WidgetKit et AppIntents.
            """
        case .romanian:
            return """
            Versiunea 1.0.0

            Un player ușor și nativ pentru bara de meniu macOS cu widget de desktop pentru YouTube Music.

            Funcții principale:
            • Fereastră în bara de meniu: controale complete de redare, bară de progres și vizualizare a cozii.
            • Widgeturi interactive: controlează redarea și schimbă playlisturile direct din widgeturile macOS prin AppIntents.
            • Integrare media de sistem: suport complet pentru Centrul de control, metadatele Acum se redă și tastele media.
            • Suport multilingv: disponibil în 10 limbi cu schimbare instantanee a interfeței.
            • Motor web în fundal: rulează într-un container dedicat pentru o redare audio neîntreruptă.

            Construit cu SwiftUI, WebKit, WidgetKit și AppIntents.
            """
        case .polish:
            return """
            Wersja 1.0.0

            Lekki, natywny odtwarzacz na pasek menu macOS oraz widżet biurkowy dla YouTube Music.

            Główne funkcje:
            • Okno na pasku menu: pełne sterowanie odtwarzaniem, pasek postępu i podgląd kolejki.
            • Interaktywne widżety: steruj odtwarzaniem i przełączaj playlisty bezpośrednio z widżetów macOS przez AppIntents.
            • Integracja systemowa: pełna obsługa Centrum sterowania, metadanych Odtwarzane oraz klawiszy multimedialnych.
            • Wersje językowe: obsługa 10 języków ze zmianą interfejsu w czasie rzeczywistym.
            • Silnik sieciowy w tle: działa w dedykowanym kontenerze w tle, zapewniając płynne odtwarzanie dźwięku.

            Stworzono przy użyciu SwiftUI, WebKit, WidgetKit i AppIntents.
            """
        }
    }
}
