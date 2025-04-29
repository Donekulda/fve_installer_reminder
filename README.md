# FVE Installer Reminder

A Flutter application for managing and tracking FVE (Photovoltaic Power Plant) installations.

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue)](https://github.com/Donekulda/fve_installer_reminder)

## English

### Description
FVE Installer Reminder is a comprehensive application designed to help manage and track photovoltaic power plant installations. The application provides a robust platform for installers, builders, and administrators to coordinate and monitor FVE installation projects.

### Key Features
- **User Management**
  - Multi-level user roles (Admin, Installer, Builder, Visitor)
  - Secure authentication system
  - User account management and privileges control
  - Role-based access control (RBAC)
  - User activity logging and audit trails

- **Installation Management**
  - Track multiple FVE installations
  - Store installation details including name and address
  - View installation status and progress
  - Installation timeline tracking
  - Custom installation checklists
  - Installation documentation management

- **Image Management**
  - Required image templates for installations
  - Image upload and storage
  - Cloud synchronization with OneDrive
  - Image description and categorization
  - Image compression and optimization
  - Batch image processing
  - Image metadata management

- **Cloud Integration**
  - OneDrive integration for data backup
  - Automatic synchronization of images
  - Offline capability with local storage
  - Conflict resolution for offline changes
  - Selective sync options
  - Bandwidth optimization

- **Multi-language Support**
  - English and Czech language interface
  - Easy language switching
  - Localized content
  - RTL support
  - Dynamic content translation
  - Language-specific formatting

### Technical Features
- Built with Flutter for cross-platform compatibility
- Secure data storage and transmission
- Offline-first architecture
- Responsive design for various screen sizes
- Comprehensive logging system
- Material Design 3 implementation
- State management using Provider
- Local database using SQLite
- RESTful API integration
- Push notification support
- Deep linking capabilities

### Requirements
- Flutter SDK (version 3.0.0 or higher)
- OneDrive account for cloud synchronization
- Platform-specific permissions for image storage
- Minimum Android API level 21
- iOS 11.0 or higher
- Internet connection for cloud sync
- 100MB of free storage space

### Getting Started
1. Clone the repository:
```bash
git clone https://github.com/Donekulda/fve_installer_reminder.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure credentials in the app settings

4. Check config files in lib/core/config

5. Run the app:
```bash
flutter run
```

### Contributing
We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Čeština

### Popis
FVE Installer Reminder je komplexní aplikace určená pro správu a sledování fotovoltaických elektráren. Aplikace poskytuje robustní platformu pro instalatéry, stavitele a administrátory ke koordinaci a monitorování projektů instalace FVE.

### Hlavní funkce
- **Správa uživatelů**
  - Víceúrovňové uživatelské role (Admin, Instalatér, Stavitel, Návštěvník)
  - Bezpečný autentizační systém
  - Správa uživatelských účtů a kontrola oprávnění

- **Správa instalací**
  - Sledování více FVE instalací
  - Ukládání detailů instalace včetně názvu a adresy
  - Zobrazení stavu a průběhu instalace

- **Správa obrázků**
  - Šablony požadovaných obrázků pro instalace
  - Nahrávání a ukládání obrázků
  - Cloudová synchronizace s OneDrive
  - Popis a kategorizace obrázků

- **Cloudová integrace**
  - Integrace s OneDrive pro zálohování dat
  - Automatická synchronizace obrázků
  - Možnost offline práce s lokálním úložištěm

- **Vícejazyčná podpora**
  - Rozhraní v angličtině a češtině
  - Snadné přepínání jazyků
  - Lokalizovaný obsah

### Technické funkce
- Vytvořeno ve Flutteru pro multiplatformní kompatibilitu
- Bezpečné ukládání a přenos dat
- Architektura s podporou offline režimu
- Responzivní design pro různé velikosti obrazovek
- Komplexní systém logování

### Požadavky
- Flutter SDK
- OneDrive účet pro cloudovou synchronizaci
- Platformově specifická oprávnění pro ukládání obrázků
