// MARK: MQGram - Detailed Ghost Mode Texts
import Foundation

// Detailed typing action texts
struct MQGramDetailedTexts {
    // Typing actions
    let ghostTypingTextTitle: String
    let ghostTypingTextText: String
    let ghostRecordingVoiceTitle: String
    let ghostRecordingVoiceText: String
    let ghostUploadingVoiceTitle: String
    let ghostUploadingVoiceText: String
    let ghostRecordingVideoTitle: String
    let ghostRecordingVideoText: String
    let ghostUploadingVideoTitle: String
    let ghostUploadingVideoText: String
    let ghostUploadingPhotoTitle: String
    let ghostUploadingPhotoText: String
    let ghostUploadingFileTitle: String
    let ghostUploadingFileText: String
    let ghostChoosingLocationTitle: String
    let ghostChoosingLocationText: String
    let ghostChoosingContactTitle: String
    let ghostChoosingContactText: String
    let ghostPlayingGameTitle: String
    let ghostPlayingGameText: String
    let ghostRecordingRoundTitle: String
    let ghostRecordingRoundText: String
    let ghostUploadingRoundTitle: String
    let ghostUploadingRoundText: String
    let ghostSpeakingInGroupCallTitle: String
    let ghostSpeakingInGroupCallText: String
    let ghostChoosingStickerTitle: String
    let ghostChoosingStickerText: String
    let ghostEmojiInteractionTitle: String
    let ghostEmojiInteractionText: String
    let ghostEmojiReactionTitle: String
    let ghostEmojiReactionText: String
    
    // Section headers
    let advancedSettingsTitle: String
    let advancedSettingsSubtitle: String
}

func mqgramDetailedTexts(_ languageCode: String) -> MQGramDetailedTexts {
    if languageCode.lowercased().hasPrefix("ru") {
        return MQGramDetailedTexts(
            // Typing actions - Russian
            ghostTypingTextTitle: "Скрыть статус набора",
            ghostTypingTextText: "Не показывать, что вы печатаете сообщение.",
            ghostRecordingVoiceTitle: "Скрыть запись голосового сообщения",
            ghostRecordingVoiceText: "Не показывать, что вы записываете голосовое сообщение.",
            ghostUploadingVoiceTitle: "Скрыть загрузку голосового сообщения",
            ghostUploadingVoiceText: "Не показывать, что вы загружаете голосовое сообщение.",
            ghostRecordingVideoTitle: "Скрыть статус записи видео",
            ghostRecordingVideoText: "Не показывать, что вы записываете видео.",
            ghostUploadingVideoTitle: "Скрыть статус загрузки видео",
            ghostUploadingVideoText: "Скрывать при загрузке видео.",
            ghostUploadingPhotoTitle: "Скрыть статус загрузки фото",
            ghostUploadingPhotoText: "Скрывать при загрузке фото.",
            ghostUploadingFileTitle: "Скрыть статус загрузки файла",
            ghostUploadingFileText: "Не показывать, что вы загружаете файл.",
            ghostChoosingLocationTitle: "Скрыть выбор локации",
            ghostChoosingLocationText: "Не показывать, что вы выбираете местоположение.",
            ghostChoosingContactTitle: "Скрыть выбор контакта",
            ghostChoosingContactText: "Не показывать, что вы выбираете контакт.",
            ghostPlayingGameTitle: "Скрыть игру",
            ghostPlayingGameText: "Не показывать, что вы играете в игру.",
            ghostRecordingRoundTitle: "Скрыть запись круглого видео",
            ghostRecordingRoundText: "Не показывать, что вы записываете круглое видео.",
            ghostUploadingRoundTitle: "Скрыть загрузку круглого видео",
            ghostUploadingRoundText: "Скрыть загрузку круглого видео.",
            ghostSpeakingInGroupCallTitle: "Скрыть голос в групповом звонке",
            ghostSpeakingInGroupCallText: "Не показывать, что вы говорите в групповом звонке.",
            ghostChoosingStickerTitle: "Скрыть выбор стикера",
            ghostChoosingStickerText: "Не показывать, что вы выбираете стикер.",
            ghostEmojiInteractionTitle: "Скрыть взаимодействие с эмодзи",
            ghostEmojiInteractionText: "Не показывать, что вы взаимодействуете с эмодзи.",
            ghostEmojiReactionTitle: "Скрыть реакцию эмодзи",
            ghostEmojiReactionText: "Не показывать, что вы реагируете на сообщение эмодзи.",
            
            // Section headers
            advancedSettingsTitle: "Расширенные настройки",
            advancedSettingsSubtitle: "Скрыть детальные настройки"
        )
    }
    
    // English
    return MQGramDetailedTexts(
        // Typing actions - English
        ghostTypingTextTitle: "Hide Typing Status",
        ghostTypingTextText: "Don't show that you are typing a message.",
        ghostRecordingVoiceTitle: "Hide Recording Voice Message",
        ghostRecordingVoiceText: "Don't show that you are recording a voice message.",
        ghostUploadingVoiceTitle: "Hide Uploading Voice Message",
        ghostUploadingVoiceText: "Don't show that you are uploading a voice message.",
        ghostRecordingVideoTitle: "Hide Recording Video Status",
        ghostRecordingVideoText: "Don't show that you are recording video.",
        ghostUploadingVideoTitle: "Hide Uploading Video Status",
        ghostUploadingVideoText: "Hide when uploading video.",
        ghostUploadingPhotoTitle: "Hide Uploading Photo Status",
        ghostUploadingPhotoText: "Hide when uploading photo.",
        ghostUploadingFileTitle: "Hide Uploading File Status",
        ghostUploadingFileText: "Don't show that you are uploading a file.",
        ghostChoosingLocationTitle: "Hide Choosing Location",
        ghostChoosingLocationText: "Don't show that you are choosing a location.",
        ghostChoosingContactTitle: "Hide Choosing Contact",
        ghostChoosingContactText: "Don't show that you are choosing a contact.",
        ghostPlayingGameTitle: "Hide Playing Game",
        ghostPlayingGameText: "Don't show that you are playing a game.",
        ghostRecordingRoundTitle: "Hide Recording Round Video",
        ghostRecordingRoundText: "Don't show that you are recording a round video.",
        ghostUploadingRoundTitle: "Hide Uploading Round Video",
        ghostUploadingRoundText: "Hide uploading round video.",
        ghostSpeakingInGroupCallTitle: "Hide Voice in Group Call",
        ghostSpeakingInGroupCallText: "Don't show that you are speaking in a group call.",
        ghostChoosingStickerTitle: "Hide Choosing Sticker",
        ghostChoosingStickerText: "Don't show that you are choosing a sticker.",
        ghostEmojiInteractionTitle: "Hide Emoji Interaction",
        ghostEmojiInteractionText: "Don't show that you are interacting with emoji.",
        ghostEmojiReactionTitle: "Hide Emoji Reaction",
        ghostEmojiReactionText: "Don't show that you are reacting to a message with emoji.",
        
        // Section headers
        advancedSettingsTitle: "Advanced Settings",
        advancedSettingsSubtitle: "Hide detail settings"
    )
}
