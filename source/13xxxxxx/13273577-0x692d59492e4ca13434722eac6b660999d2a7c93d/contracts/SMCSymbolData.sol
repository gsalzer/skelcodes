// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./ISMCSymbol.sol";

contract SMCSymbolData is ISMCSymbolData {
    string[] public japaneseZodiacs = [
        "NE (Rat)",
        "USHI (Ox)",
        "TORA (Tiger)",
        "U (Rabbit)",
        "TATSU (Dragon)",
        "MI (Snake)",
        "UMA (Horse)",
        "HITSUJI (Sheep)",
        "SARU (Monkey)",
        "YORI (Rooster)",
        "INU (Dog)",
        "I (Boar)"
    ];

    function JapaneseZodiacs()
        external
        view
        override
        returns (string[] memory)
    {
        return japaneseZodiacs;
    }

    string[] public CodesOfArts = [
        "Seditious",
        "Fastidious",
        "Malicious",
        "Audacious",
        "Pernicious",
        "Viscous",
        "Capricious",
        "Stratify",
        "Dignify",
        "Defy",
        "Satisfy",
        "Pacify",
        "Nullify"
    ];

    string[] public rarities = [
        "",
        "",
        "Stardust",
        "Soldier",
        "Ninja",
        "Shogun",
        "",
        "",
        "",
        ""
    ];

    function Rarities() external view override returns (string[] memory) {
        return rarities;
    }

    string[] public initials = [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z"
    ];

    function Initials() external view override returns (string[] memory) {
        return initials;
    }

    string[] public firstNames = [
        "Oichi",
        "Naka",
        "Nene",
        "Francisco",
        "Matsu",
        "Luis",
        "Shigezane",
        "Masamune",
        "Mancio",
        "Naotora",
        "Naomasa",
        "Ittetsu",
        "Naoie",
        "Hirotsuna",
        "Hidekatsu",
        "Eihime",
        "Oman",
        "Motonobu",
        "Kiyomasa",
        "Saizo",
        "Harunobu",
        "Ujisato",
        "Tsunamoto",
        "Akimasa",
        "Musashi",
        "Maria",
        "Yoshitaka",
        "Oribe",
        "Matabei",
        "Teruhime",
        "Go",
        "Kaihime",
        "Murashige",
        "Ukon",
        "Kanbei",
        "Mototaka",
        "Munehisa",
        "Yoshimoto",
        "Narimasa",
        "Kojiro",
        "Yoshimutsu",
        "Yoshitatsu",
        "Dosan",
        "Toshimitsu",
        "Tatsuoki",
        "Garasha",
        "Tadaoki",
        "Yusai",
        "Yasumasa",
        "Magoichi",
        "Nagayoshi",
        "Tokitsugu",
        "Masakage",
        "Kazutoyo",
        "Kansuke",
        "Yoritsuna",
        "Tsunenaga",
        "Bokuzen",
        "Katsuie",
        "Eitoku",
        "Okuni",
        "Hatsu",
        "Yukinaga",
        "Hideaki",
        "Takakage",
        "Enshu",
        "Hisahide",
        "Tadateru",
        "Tadanao",
        "Kagetora",
        "Kagekatsu",
        "Kenshin",
        "Nobutaka",
        "Nobuhide",
        "Nobutada",
        "Nobunaga",
        "Ranmaru",
        "Yukimura",
        "Masayuki",
        "Goemon",
        "Mitsunari",
        "Hidehisa",
        "Chiyo",
        "Rikyu",
        "Nagamasa",
        "Keiji",
        "Toshie",
        "Nagamori",
        "Yoshihide",
        "Yoshiteru",
        "Yoshiaki",
        "Toshikiyo",
        "Sessai",
        "Gyuichi",
        "Dokan",
        "Tadachika",
        "Masashige",
        "Yoshioki",
        "Yoshimune",
        "Sorin",
        "Kazumasu",
        "Terumasa",
        "Tsuneoki",
        "Hanbei",
        "Chacha",
        "Shirojiro",
        "Yoshikage",
        "Asahihime",
        "Motochika",
        "Tohaku",
        "Kanetsugu",
        "Sokyu",
        "Tsuruhime",
        "Sakon",
        "Yoshihiro",
        "Takatora",
        "Ieyasu",
        "Hidetada",
        "Tenkai",
        "Yoshihisa",
        "Katsuhisa",
        "Haruhisa",
        "Nohime",
        "Toramasa",
        "Sotatsu",
        "Yoshinobu",
        "Katsuyori",
        "Shingen",
        "Nobutora",
        "Kotaro",
        "Hanzo",
        "Masanori",
        "Kojuro",
        "Tomonobu",
        "Koroku",
        "Hideyoshi",
        "Hidenaga",
        "Hideyori",
        "Tsurumatsu",
        "Ujiyasu",
        "Ujimasa",
        "Soun",
        "Masanobu",
        "Tadakatsu",
        "Mitsuhide",
        "Terumoto",
        "Motonari",
        "Munenori",
        "Ginchiyo",
        "Yasuke"
    ];

    function FirstNames() external view override returns (string[] memory) {
        return firstNames;
    }

    string[] public nativePlaces = [
        "Omi",
        "Mino",
        "Hida",
        "Shinano",
        "Kozuke",
        "Shimotsuke",
        "Mutsu",
        "Wakasa",
        "Echizen",
        "Kaga",
        "Noto",
        "Etchu",
        "Echigo",
        "Sado",
        "Iga",
        "Ise",
        "Shima",
        "Owari",
        "Mikawa",
        "Totomi",
        "Suruga",
        "Izu",
        "Kai",
        "Sagami",
        "Musashi",
        "Awa",
        "Kazusa",
        "Shimousa",
        "Hitachi",
        "Yamato",
        "Yamashiro",
        "Settsu",
        "Kawachi",
        "Izumi",
        "Tanba",
        "Tango",
        "Tajima",
        "Inaba",
        "Hoki",
        "Izumo",
        "Iwami",
        "Oki",
        "Harima",
        "Mimasaka",
        "Bizen",
        "Bitchu",
        "Bingo",
        "Aki",
        "Suo",
        "Nagato",
        "Kii",
        "Awaji",
        "Sanuki",
        "Iyo",
        "Tosa",
        "Chikuzen",
        "Chikugo",
        "Buzen",
        "Bungo",
        "Hizen",
        "Higo",
        "Hyuga",
        "Osumi",
        "Satsuma",
        "Iki",
        "Tsushima",
        "Ezo",
        "Ryukyu",
        "Portugal",
        "Mozambique",
        "Joseon",
        "Netherlands",
        "England",
        "Ming",
        "Moon",
        "Underworld",
        "Unknown"
    ];

    function NativePlaces() external view override returns (string[] memory) {
        return nativePlaces;
    }

    string[] public colors = [
        "",
        "Red",
        "Green",
        "Blue",
        "Purple",
        "White",
        "Sakura",
        "Navy"
    ];

    function Colors() external view override returns (string[] memory) {
        return colors;
    }

    string[] public patterns = [
        "Ichimatsu",
        "Asanoha",
        "Seigaiha",
        "Uroko",
        "Yagasuri",
        "Shichiyoumon",
        "Mitsudomoe",
        "Sankuzushi",
        "Chidori",
        "Kikkou",
        "Plain"
    ];

    function Patterns() external view override returns (string[] memory) {
        return patterns;
    }

    constructor() {}
}

