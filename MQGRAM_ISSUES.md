# MQGram Issues & TODO List

## 🔴 CRITICAL ISSUES (Need Immediate Fix)

### None found - Code is stable

---

## 🟡 HIGH PRIORITY (Should be fixed before release)

### 1. AutoTranslate Implementation
- **File:** `submodules/TelegramUI/Sources/ChatController.swift` (line 8478)
- **Current State:** Only adds `[lang→en]` prefix, doesn't actually translate
- **Issue:** SGGTranslate imported but not fully integrated
- **Fix Required:** 
  ```swift
  // Current (WRONG):
  transformedText = "[\(currentLang)→en] " + transformedText
  
  // Should be (async translate):
  translateText(transformedText, to: targetLanguage) { result in
      // Send translated message
  }
  ```

### 2. Registration Date Display
- **File:** Part of Swiftgram's SGRegDate module
- **Current State:** Key exists but integration unclear
- **Issue:** Needs verification that SGRegDate module is properly connected
- **Status:** Bridge created in MQGramSettingsController, needs testing

---

## 🟠 MEDIUM PRIORITY (Nice to have)

### 3. Custom Font Support
- **Keys:** `customFont`, `customFontName`, `customFontPath`
- **Current State:** Only settings, no implementation
- **Issue:** Need FontManager to load .ttf/.otf files
- **Recommended Solution:**
  - Create FontManager class
  - Load custom fonts in application(_:didFinishLaunchingWithOptions:)
  - Apply to all UILabel/UITextField via appearance proxy

### 4. Video Background for Chats
- **Keys:** `videoBackground`, `videoBackgroundPath`
- **Current State:** Only settings, no rendering
- **Issue:** Need AVPlayer integration in ChatHistoryNode
- **Recommended Solution:**
  - Integrate AVPlayer in ChatBackgroundView
  - Loop video in background
  - Make it low-opacity overlay

### 5. Full Russian UI Localization
- **Key:** `fullRussianUI`
- **Current State:** No implementation
- **Issue:** Would require translating entire TelegramUI
- **Effort:** Very High (1000+ strings)
- **Recommendation:** Use Crowdin for community translation

### 6. Hide UI Elements
- **Keys:** `hideNavigationBar`, `hideFavoriteChats`, `hideRecentCalls`, etc.
- **Current State:** No implementation
- **Files Affected:** 
  - TabBarController (for main tabs)
  - ChatListController (for chats list)
  - ChatController (for nav bar)
- **Effort:** Medium-High

---

## 🟢 LOW PRIORITY (Future enhancement)

### 7. Enhanced Message Delay Randomization
- **Current:** Uses `arc4random_uniform(6) + 2` (2-7 seconds)
- **Could Add:**
  - User-configurable min/max delay
  - Gaussian distribution instead of uniform
  - Per-chat delay settings

### 8. Anti-Caps Exceptions
- **Current:** Simply converts to lowercase if 100% CAPS and > 2 chars
- **Could Add:**
  - Whitelist of acronyms (OK, LOL, FAQ, etc.)
  - Per-message exception via hotkey
  - Smart detection of intentional CAPS

### 9. Always Online/Offline Refinements
- **Could Add:**
  - Scheduled auto-switching (work hours vs. off hours)
  - Per-chat rules (always online in work chats, offline in personal)
  - Randomized ping intervals to appear more natural

---

## ✅ VERIFIED WORKING

- [x] Ghost Mode (all 12 features)
- [x] Content Protection (all 4 features)
- [x] Deleted Message Logging
- [x] Edit History Viewing
- [x] Always Online/Offline (with mutual exclusion)
- [x] Message Sending Delay
- [x] AntiCaps
- [x] Square Avatars
- [x] Local Premium Badge
- [x] Secret Media Saving

---

## 📝 TESTING CHECKLIST

### Before Release:
- [ ] Test Ghost Mode in group chats
- [ ] Verify Edit History works with deleted messages
- [ ] Test Always Online ping doesn't spam server
- [ ] Verify AntiCaps doesn't break URLs/hashtags
- [ ] Test message delay on slow networks
- [ ] Verify saved deleted messages persist after app restart
- [ ] Test local premium limits
- [ ] Check battery impact of Always Online

---

## 🚀 NEXT STEPS

1. **Immediate:** None - code is stable
2. **Next Release:** Implement AutoTranslate properly
3. **Later:** Add Custom Font & Video Background
4. **Eventually:** Consider Full Russian UI if community interest

---

## 📞 CONTACT FOR QUESTIONS

- Issues tracker: GitHub Issues
- Documentation: See MQGRAM_FUNCTIONS_AUDIT.md
