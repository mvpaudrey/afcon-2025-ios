//
//  String+TeamNames.swift
//  TournamentKit
//

import Foundation

// MARK: - Localization helpers

private func currentLanguageCode() -> String {
    if AppSettings.shared.hasCustomLanguage {
        return AppSettings.shared.appLanguage.rawValue
    }
    return Locale.current.language.languageCode?.identifier ?? "en"
}

public func localizedGroupName(_ name: String) -> String {
    let suffix = name.hasPrefix("Group ") ? String(name.dropFirst(6)) : name
    switch currentLanguageCode() {
    case "fr": return "Groupe \(suffix)"
    case "ar": return "المجموعة \(suffix)"
    default:   return name
    }
}

public func localizedTeamName(_ name: String) -> String {
    // Normalize: if the stored name is a French localized name (e.g. "Maroc"),
    // resolve it back to the English key before doing the target-language lookup.
    let englishKey = frenchToEnglishNames[name] ?? name
    switch currentLanguageCode() {
    case "fr": return frenchTeamNames[englishKey] ?? name
    case "ar": return arabicTeamNames[englishKey] ?? name
    default:   return englishKey
    }
}

private let frenchTeamNames: [String: String] = [
    // AFCON teams
    "Morocco": "Maroc",
    "Senegal": "Sénégal",
    "Algeria": "Algérie",
    "Tunisia": "Tunisie",
    "Egypt": "Égypte",
    "Nigeria": "Nigeria",
    "Cameroon": "Cameroun",
    "Ghana": "Ghana",
    "Ivory Coast": "Côte d'Ivoire",
    "Cote d'Ivoire": "Côte d'Ivoire",
    "Côte d'Ivoire": "Côte d'Ivoire",
    "South Africa": "Afrique du Sud",
    "Mali": "Mali",
    "Burkina Faso": "Burkina Faso",
    "Guinea": "Guinée",
    "Guinea-Bissau": "Guinée-Bissau",
    "Equatorial Guinea": "Guinée équatoriale",
    "Gabon": "Gabon",
    "Angola": "Angola",
    "Zambia": "Zambie",
    "Zimbabwe": "Zimbabwe",
    "Tanzania": "Tanzanie",
    "Comoros": "Comores",
    "Botswana": "Botswana",
    "Benin": "Bénin",
    "Uganda": "Ouganda",
    "Mozambique": "Mozambique",
    "DR Congo": "RD Congo",
    "Congo DR": "RD Congo",
    "Democratic Republic of the Congo": "RD Congo",
    "Sudan": "Soudan",
    // WC 2026 teams
    "France": "France",
    "Germany": "Allemagne",
    "Spain": "Espagne",
    "Portugal": "Portugal",
    "Netherlands": "Pays-Bas",
    "Belgium": "Belgique",
    "England": "Angleterre",
    "Scotland": "Écosse",
    "Sweden": "Suède",
    "Norway": "Norvège",
    "Denmark": "Danemark",
    "Austria": "Autriche",
    "Switzerland": "Suisse",
    "Czech Republic": "République tchèque",
    "Croatia": "Croatie",
    "Turkey": "Turquie",
    "Poland": "Pologne",
    "Ukraine": "Ukraine",
    "Romania": "Roumanie",
    "Hungary": "Hongrie",
    "Bosnia & Herzegovina": "Bosnie-Herzégovine",
    "Bosnia": "Bosnie-Herzégovine",
    "Serbia": "Serbie",
    "Slovakia": "Slovaquie",
    "Slovenia": "Slovénie",
    "Greece": "Grèce",
    "Brazil": "Brésil",
    "Argentina": "Argentine",
    "Colombia": "Colombie",
    "Ecuador": "Équateur",
    "Uruguay": "Uruguay",
    "Paraguay": "Paraguay",
    "Chile": "Chili",
    "Venezuela": "Venezuela",
    "Peru": "Pérou",
    "Bolivia": "Bolivie",
    "Mexico": "Mexique",
    "United States": "États-Unis",
    "USA": "États-Unis",
    "Canada": "Canada",
    "Costa Rica": "Costa Rica",
    "Panama": "Panama",
    "Honduras": "Honduras",
    "Jamaica": "Jamaïque",
    "Haiti": "Haïti",
    "Trinidad and Tobago": "Trinité-et-Tobago",
    "Curacao": "Curaçao",
    "Japan": "Japon",
    "South Korea": "Corée du Sud",
    "Korea Republic": "Corée du Sud",
    "Australia": "Australie",
    "Saudi Arabia": "Arabie saoudite",
    "Iran": "Iran",
    "Iraq": "Irak",
    "Jordan": "Jordanie",
    "Qatar": "Qatar",
    "Uzbekistan": "Ouzbékistan",
    "New Zealand": "Nouvelle-Zélande",
    "Cape Verde": "Cap-Vert",
    "Cabo Verde": "Cap-Vert"
]

private let arabicTeamNames: [String: String] = [
    // Africa (AFCON + WC)
    "Morocco": "المغرب",
    "Senegal": "السنغال",
    "Algeria": "الجزائر",
    "Tunisia": "تونس",
    "Egypt": "مصر",
    "Nigeria": "نيجيريا",
    "Cameroon": "الكاميرون",
    "Ghana": "غانا",
    "Ivory Coast": "كوت ديفوار",
    "Cote d'Ivoire": "كوت ديفوار",
    "Côte d'Ivoire": "كوت ديفوار",
    "South Africa": "جنوب أفريقيا",
    "Mali": "مالي",
    "Burkina Faso": "بوركينا فاسو",
    "Guinea": "غينيا",
    "Guinea-Bissau": "غينيا بيساو",
    "Equatorial Guinea": "غينيا الاستوائية",
    "Gabon": "الغابون",
    "Angola": "أنغولا",
    "Zambia": "زامبيا",
    "Zimbabwe": "زيمبابوي",
    "Tanzania": "تنزانيا",
    "Comoros": "جزر القمر",
    "Botswana": "بوتسوانا",
    "Benin": "بنين",
    "Uganda": "أوغندا",
    "Mozambique": "موزمبيق",
    "DR Congo": "جمهورية الكونغو الديمقراطية",
    "Congo DR": "جمهورية الكونغو الديمقراطية",
    "Democratic Republic of the Congo": "جمهورية الكونغو الديمقراطية",
    "Sudan": "السودان",
    "Cape Verde": "الرأس الأخضر",
    "Cabo Verde": "الرأس الأخضر",
    // Europe
    "France": "فرنسا",
    "Germany": "ألمانيا",
    "Spain": "إسبانيا",
    "Portugal": "البرتغال",
    "Netherlands": "هولندا",
    "Belgium": "بلجيكا",
    "England": "إنجلترا",
    "Scotland": "اسكتلندا",
    "Sweden": "السويد",
    "Norway": "النرويج",
    "Denmark": "الدنمارك",
    "Austria": "النمسا",
    "Switzerland": "سويسرا",
    "Czech Republic": "جمهورية التشيك",
    "Croatia": "كرواتيا",
    "Turkey": "تركيا",
    "Poland": "بولندا",
    "Ukraine": "أوكرانيا",
    "Romania": "رومانيا",
    "Hungary": "المجر",
    "Bosnia & Herzegovina": "البوسنة والهرسك",
    "Bosnia": "البوسنة والهرسك",
    "Serbia": "صربيا",
    "Slovakia": "سلوفاكيا",
    "Slovenia": "سلوفينيا",
    "Greece": "اليونان",
    // South America
    "Brazil": "البرازيل",
    "Argentina": "الأرجنتين",
    "Colombia": "كولومبيا",
    "Ecuador": "الإكوادور",
    "Uruguay": "أوروغواي",
    "Paraguay": "باراغواي",
    "Chile": "تشيلي",
    "Venezuela": "فنزويلا",
    "Peru": "بيرو",
    "Bolivia": "بوليفيا",
    // CONCACAF
    "Mexico": "المكسيك",
    "United States": "الولايات المتحدة",
    "USA": "الولايات المتحدة",
    "Canada": "كندا",
    "Costa Rica": "كوستاريكا",
    "Panama": "بنما",
    "Honduras": "هندوراس",
    "Jamaica": "جامايكا",
    "Haiti": "هايتي",
    "Trinidad and Tobago": "ترينيداد وتوباغو",
    "Curacao": "كوراساو",
    // Asia & Oceania
    "Japan": "اليابان",
    "South Korea": "كوريا الجنوبية",
    "Korea Republic": "كوريا الجنوبية",
    "Australia": "أستراليا",
    "Saudi Arabia": "المملكة العربية السعودية",
    "Iran": "إيران",
    "Iraq": "العراق",
    "Jordan": "الأردن",
    "Qatar": "قطر",
    "Uzbekistan": "أوزبكستان",
    "New Zealand": "نيوزيلندا"
]

// Reverse lookup: French display name → English canonical key.
// Handles the case where team names were stored in French in SwiftData
// (via GRPCModelExtensions) and need to be re-normalized before translation.
private let frenchToEnglishNames: [String: String] = {
    var dict: [String: String] = [:]
    for (english, french) in frenchTeamNames where english != french {
        dict[french] = english
    }
    return dict
}()
