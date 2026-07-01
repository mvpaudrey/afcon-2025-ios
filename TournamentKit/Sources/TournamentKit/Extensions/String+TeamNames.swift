//
//  String+TeamNames.swift
//  TournamentKit
//

import Foundation

// MARK: - Localization helpers

public func localizedTeamName(_ name: String) -> String {
    let language = Locale.current.language.languageCode?.identifier ?? "fr"

    switch language {
    case "fr":
        return frenchTeamNames[name] ?? name
    case "ar":
        return arabicTeamNames[name] ?? name
    default:
        return name
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
    "Sudan": "السودان"
]
