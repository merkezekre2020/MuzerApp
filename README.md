# Muzer

Muzer, cihazın now playing bilgisini okuyup LRCLIB API ile söz getiren SwiftUI tabanlı bir iOS 16+ uygulama iskeletidir.

## Proje Yapısı

- `Muzer/App`: Uygulama giriş noktası
- `Muzer/Models`: Domain modelleri
- `Muzer/Services`: Apple medya bilgisi ve LRCLIB ağ katmanı
- `Muzer/ViewModels`: MVVM state yönetimi
- `Muzer/Views`: Ekranlar ve state bileşenleri
- `Muzer/Utils`: LRC parse ve zaman format yardımcıları
- `Muzer/Resources`: Asset ve preview kaynakları

## Gerekli Frameworkler

- SwiftUI
- Foundation
- MediaPlayer
- UIKit (bildirim ve artwork dönüşümü için)

## Info.plist Notları

Aşağıdaki anahtarları ekleyin:

- `NSAppleMusicUsageDescription`: Muzer, çalan parçayı ve metadata'yı okuyup söz gösterebilmek için Apple Music erişimi ister.

## Capability Notları

- Signing & Capabilities altında **MusicKit** yeteneğini açın.
- Geliştirme sırasında gerçek cihazda test önerilir; simülatörde now playing bilgisi sınırlı olabilir.

## Çalıştırma

1. Xcode'da yeni iOS App projesi oluşturun (adı: `Muzer`, iOS 16+).
2. Bu depodaki `Muzer/` klasörünü proje içine grup yapısını koruyarak ekleyin.
3. Info.plist anahtarını ve MusicKit capability ayarını yapın.
4. Uygulamayı gerçek cihazda başlatın, Apple Music veya sistem medya oynatımında bir parça açın.
5. Muzer otomatik algılayıp sözleri getirir; gerekirse sağ üstten yenileyin.

## GitHub Release Workflow (Unsigned IPA)

Bu repoda `.github/workflows/release-unsigned-ipa.yml` workflow'u bulunur.

- `v*` tag push edildiğinde veya manuel (`workflow_dispatch`) tetiklendiğinde çalışır.
- `Muzer` şemasını `Release` konfigürasyonunda imzasız archive alır.
- Archive içindeki `.app` paketini `Payload` içine koyup imzasız `.ipa` üretir.
- Hem Actions artifact olarak yükler hem de ilgili GitHub Release'e ekler.

> Not: Bu IPA imzasızdır; doğrudan gerçek cihaza kurulamaz. Dağıtım için ayrıca signing gerekir.
