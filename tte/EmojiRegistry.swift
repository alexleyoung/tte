//
//  EmojiRegistry.swift
//  tte
//
//  Created by Alex Young on 11/25/25.
//

import Foundation

/// Registry of emoji shortcodes and their corresponding emoji characters.
/// Uses Discord-compatible shortcode format (e.g., ":fire:" -> 🔥)
class EmojiRegistry {
    static let shared = EmojiRegistry()

    /// Dictionary mapping shortcodes to emoji characters
    private(set) var mappings: [String: String] = [:]

    /// Dictionary tracking usage count for each shortcode
    private var usageCounts: [String: Int] = [:]

    /// UserDefaults key for persisting usage counts
    private let usageCountsKey = "emojiUsageCounts"

    /// Path to the emoji JSON file
    private let emojiFilePath: String

    private init() {
        // Set up the emoji file path in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("tte")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        emojiFilePath = appDir.appendingPathComponent("emojis.json").path
        
        // Copy default emoji file if it doesn't exist
        if !FileManager.default.fileExists(atPath: emojiFilePath) {
            createDefaultEmojiFile()
        }
        
        loadEmojis()
        loadUsageCounts()
    }

    /// Load emojis from the JSON file
    private func loadEmojis() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: emojiFilePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("Warning: Could not load emojis from \(emojiFilePath), using empty dictionary")
            mappings = [:]
            return
        }
        mappings = json
    }

    /// Reload emojis from disk (useful when file is edited externally)
    func reloadEmojis() {
        loadEmojis()
    }

    /// Get the path where the emoji file is stored
    func getEmojiFilePath() -> String {
        return emojiFilePath
    }

    /// Create the default emoji JSON file with all built-in emojis
    private func createDefaultEmojiFile() {
        let defaultEmojis: [String: String] = [
            // Smileys & Emotion
            ":grinning:": "😀",
            ":smiley:": "😃",
            ":smile:": "😄",
            ":grin:": "😁",
            ":laughing:": "😆",
            ":sweat_smile:": "😅",
            ":joy:": "😂",
            ":rofl:": "🤣",
            ":relaxed:": "☺️",
            ":blush:": "😊",
            ":smiling_face_with_tear": "🥲",
            ":innocent:": "😇",
            ":slight_smile:": "🙂",
            ":upside_down:": "🙃",
            ":wink:": "😉",
            ":relieved:": "😌",
            ":heart_eyes:": "😍",
            ":kissing_heart:": "😘",
            ":kissing:": "😗",
            ":kissing_smiling_eyes:": "😙",
            ":kissing_closed_eyes:": "😚",
            ":yum:": "😋",
            ":stuck_out_tongue:": "😛",
            ":stuck_out_tongue_closed_eyes:": "😝",
            ":stuck_out_tongue_winking_eye:": "😜",
            ":zany_face:": "🤪",
            ":face_with_raised_eyebrow:": "🤨",
            ":face_with_monocle:": "🧐",
            ":nerd:": "🤓",
            ":sunglasses:": "😎",
            ":star_struck:": "🤩",
            ":partying_face:": "🥳",
            ":smirk:": "😏",
            ":unamused:": "😒",
            ":disappointed:": "😞",
            ":pensive:": "😔",
            ":worried:": "😟",
            ":confused:": "😕",
            ":slight_frown:": "🙁",
            ":frowning2:": "☹️",
            ":persevere:": "😣",
            ":confounded:": "😖",
            ":tired_face:": "🫩",
            ":weary:": "😩",
            ":pleading_face:": "🥺",
            ":cry:": "😢",
            ":sob:": "😭",
            ":triumph:": "😤",
            ":angry:": "😠",
            ":rage:": "😡",
            ":face_with_symbols_over_mouth:": "🤬",
            ":exploding_head:": "🤯",
            ":flushed:": "😳",
            ":scream:": "😱",
            ":fearful:": "😨",
            ":cold_sweat:": "😰",
            ":disappointed_relieved:": "😥",
            ":sweat:": "😓",
            ":hugging:": "🤗",
            ":thinking:": "🤔",
            ":face_with_hand_over_mouth:": "🤭",
            ":yawning_face:": "🥱",
            ":shushing_face:": "🤫",
            ":lying_face:": "🤥",
            ":no_mouth:": "😶",
            ":neutral_face:": "😐",
            ":expressionless:": "😑",
            ":grimacing:": "😬",
            ":roll_eyes:": "🙄",
            ":hushed:": "😯",
            ":frowning:": "😦",
            ":anguished:": "😧",
            ":open_mouth:": "😮",
            ":astonished:": "😲",
            ":sleeping:": "😴",
            ":drooling_face:": "🤤",
            ":sleepy:": "😪",
            ":dizzy_face:": "😵‍💫",
            ":zipper_mouth:": "🤐",
            ":woozy_face:": "🥴",
            ":nauseated_face:": "🤢",
            ":face_vomiting:": "🤮",
            ":sneezing_face:": "🤧",
            ":mask:": "😷",
            ":thermometer_face:": "🤒",
            ":head_bandage:": "🤕",
            ":money_mouth:": "🤑",
            ":cowboy:": "🤠",
            ":smiling_imp:": "😈",
            ":imp:": "👿",
            ":japanese_ogre:": "👹",
            ":japanese_goblin:": "👺",
            ":clown:": "🤡",
            ":poop:": "💩",
            ":ghost:": "👻",
            ":skull:": "💀",
            ":skull_crossbones:": "☠️",
            ":alien:": "👽",
            ":space_invader:": "👾",
            ":robot:": "🤖",
            ":jack_o_lantern:": "🎃",
            ":smiley_cat:": "😺",
            ":smile_cat:": "😸",
            ":joy_cat:": "😹",
            ":heart_eyes_cat:": "😻",
            ":smirk_cat:": "😼",
            ":kissing_cat:": "😽",
            ":scream_cat:": "🙀",
            ":crying_cat_face:": "😿",
            ":pouting_cat:": "😾",

            // Gestures & People
            ":wave:": "👋",
            ":raised_hand:": "✋",
            ":vulcan:": "🖖",
            ":ok_hand:": "👌",
            ":v:": "✌️",
            ":crossed_fingers:": "🤞",
            ":metal:": "🤘",
            ":call_me:": "🤙",
            ":point_left:": "👈",
            ":point_right:": "👉",
            ":point_up_2:": "👆",
            ":point_down:": "👇",
            ":point_up:": "☝️",
            ":thumbsup:": "👍",
            ":thumbsdown:": "👎",
            ":fist:": "✊",
            ":facepunch:": "👊",
            ":left_facing_fist:": "🤛",
            ":right_facing_fist:": "🤜",
            ":clap:": "👏",
            ":raised_hands:": "🙌",
            ":open_hands:": "👐",
            ":palms_up_together:": "🤲",
            ":handshake:": "🤝",
            ":pray:": "🙏",
            ":writing_hand:": "✍️",
            ":nail_care:": "💅",
            ":selfie:": "🤳",
            ":muscle:": "💪",
            ":mechanical_arm:": "🦾",
            ":mechanical_leg:": "🦿",
            ":leg:": "🦵",
            ":foot:": "🦶",
            ":ear:": "👂",
            ":nose:": "👃",
            ":brain:": "🧠",
            ":eyes:": "👀",
            ":eye:": "👁️",
            ":tongue:": "👅",
            ":lips:": "👄",

            // Monkeys
            ":see_no_evil:": "🙈",
            ":hear_no_evil:": "🙉",
            ":speak_no_evil:": "🙊",

            // Hearts
            ":heart:": "❤️",
            ":orange_heart:": "🧡",
            ":yellow_heart:": "💛",
            ":green_heart:": "💚",
            ":blue_heart:": "💙",
            ":purple_heart:": "💜",
            ":black_heart:": "🖤",
            ":brown_heart:": "🤎",
            ":white_heart:": "🤍",
            ":broken_heart:": "💔",
            ":heart_exclamation:": "❣️",
            ":two_hearts:": "💕",
            ":revolving_hearts:": "💞",
            ":heartbeat:": "💓",
            ":heartpulse:": "💗",
            ":sparkling_heart:": "💖",
            ":cupid:": "💘",
            ":gift_heart:": "💝",
            ":heart_decoration:": "💟",

            // Symbols
            ":100:": "💯",
            ":fire:": "🔥",
            ":sparkles:": "✨",
            ":star:": "⭐",
            ":star2:": "🌟",
            ":dizzy:": "💫",
            ":boom:": "💥",
            ":anger:": "💢",
            ":sweat_drops:": "💦",
            ":dash:": "💨",
            ":hole:": "🕳️",
            ":speech_balloon:": "💬",
            ":eye_in_speech_bubble:": "👁️‍🗨️",
            ":thought_balloon:": "💭",
            ":zzz:": "💤",

            // Popular Objects & Activities
            ":tada:": "🎉",
            ":confetti_ball:": "🎊",
            ":rocket:": "🚀",
            ":trophy:": "🏆",
            ":medal:": "🏅",
            ":first_place:": "🥇",
            ":second_place:": "🥈",
            ":third_place:": "🥉",
            ":soccer:": "⚽",
            ":basketball:": "🏀",
            ":football:": "🏈",
            ":baseball:": "⚾",
            ":tennis:": "🎾",
            ":8ball:": "🎱",
            ":pizza:": "🍕",
            ":hamburger:": "🍔",
            ":fries:": "🍟",
            ":hotdog:": "🌭",
            ":taco:": "🌮",
            ":burrito:": "🌯",
            ":beer:": "🍺",
            ":beers:": "🍻",
            ":wine_glass:": "🍷",
            ":coffee:": "☕",
            ":tea:": "🍵",
            ":cake:": "🍰",
            ":birthday:": "🎂",
            ":cookie:": "🍪",
            ":wilted_rose:": "🥀",

            // Gestures (additional)
            ":ok:": "🆗",
            ":new:": "🆕",
            ":free:": "🆓",
            ":cool:": "🆒",
            ":sos:": "🆘",
            ":up:": "🆙",
            ":vs:": "🆚",

            // Flags (common)
            ":checkered_flag:": "🏁",
            ":triangular_flag_on_post:": "🚩",
            ":crossed_flags:": "🎌",
            ":rainbow_flag:": "🏳️‍🌈",

            // Additional common Discord emojis
            ":shrug:": "🤷",
            ":facepalm:": "🤦",
            ":ping_pong:": "🏓",
            ":microphone:": "🎤",
            ":headphones:": "🎧",
            ":video_game:": "🎮",
            ":guitar:": "🎸",
            ":musical_note:": "🎵",
            ":notes:": "🎶",
            ":bell:": "🔔",
            ":no_bell:": "🔕",
            ":mega:": "📣",
            ":loudspeaker:": "📢",
            ":book:": "📖",
            ":books:": "📚",
            ":pencil:": "📝",
            ":bulb:": "💡",
            ":mag:": "🔍",
            ":mag_right:": "🔎",
            ":lock:": "🔒",
            ":unlock:": "🔓",
            ":key:": "🔑",
            ":hammer:": "🔨",
            ":wrench:": "🔧",
            ":nut_and_bolt:": "🔩",
            ":gear:": "⚙️",
            ":link:": "🔗",
            ":chains:": "⛓️",
            ":warning:": "⚠️",
            ":no_entry:": "⛔",
            ":white_check_mark:": "✅",
            ":x:": "❌",
            ":o:": "⭕",
            ":question:": "❓",
            ":grey_question:": "❔",
            ":grey_exclamation:": "❕",
            ":exclamation:": "❗",
            ":heavy_plus_sign:": "➕",
            ":heavy_minus_sign:": "➖",
            ":heavy_division_sign:": "➗",
            ":heavy_multiplication_x:": "✖️",
            ":arrow_left:": "⬅️",
            ":arrow_right:": "➡️",
            ":arrow_up:": "⬆️",
            ":arrow_down:": "⬇️"
        ]

        do {
            let data = try JSONEncoder().encode(defaultEmojis)
            try data.write(to: URL(fileURLWithPath: emojiFilePath))
        } catch {
            print("Error creating default emoji file: \(error)")
        }
    }

    /// Returns the emoji for a given shortcode.
    /// - Parameter shortcut: The emoji shortcode (e.g., ":fire:")
    /// - Returns: The emoji character, or nil if not found
    func getEmoji(for shortcut: String) -> String? {
        return mappings[shortcut]
    }

    /// Returns all available shortcodes in alphabetical order.
    /// - Returns: Sorted array of shortcode strings
    func getAllShortcuts() -> [String] {
        return Array(mappings.keys).sorted()
    }

    /// Returns all available shortcodes sorted by usage count (most used first), then alphabetically.
    /// - Returns: Sorted array of shortcode strings
    func getShortcutsSortedByUsage() -> [String] {
        return Array(mappings.keys).sorted { shortcode1, shortcode2 in
            let count1 = usageCounts[shortcode1] ?? 0
            let count2 = usageCounts[shortcode2] ?? 0

            if count1 != count2 {
                return count1 > count2
            }
            return shortcode1 < shortcode2
        }
    }

    /// Records that an emoji shortcode was used.
    /// - Parameter shortcut: The emoji shortcode that was used
    func recordUsage(for shortcut: String) {
        usageCounts[shortcut, default: 0] += 1
        saveUsageCounts()
    }

    /// Gets the usage count for a shortcode.
    /// - Parameter shortcut: The emoji shortcode
    /// - Returns: The number of times this shortcode has been used
    func getUsageCount(for shortcut: String) -> Int {
        return usageCounts[shortcut] ?? 0
    }

    // MARK: - Persistence

    private func loadUsageCounts() {
        if let data = UserDefaults.standard.data(forKey: usageCountsKey),
           let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
            usageCounts = counts
        }
    }

    private func saveUsageCounts() {
        if let data = try? JSONEncoder().encode(usageCounts) {
            UserDefaults.standard.set(data, forKey: usageCountsKey)
        }
    }
}
