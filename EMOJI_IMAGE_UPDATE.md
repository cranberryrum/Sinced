# Emoji Picker & Image Selection Update

## Overview
Implemented new bottom sheet design with emoji picker and optional 1:1 image selection for events. Images display in the widget as background.

## Changes Made

### 1. **Model Updates** (`SinceEvent.swift`)
- ✅ Added `imageData: Data?` field to store optional 1:1 images
- ✅ Updated initializer to accept image data

### 2. **New Emoji Picker** (`EmojiPickerView.swift`)
- ✅ Created dedicated emoji picker view with search functionality
- ✅ Grid layout showing 8 emojis per row
- ✅ 200+ emojis organized by category (smileys, food, activities, health, animals, travel)
- ✅ Search bar for filtering emojis
- ✅ Haptic feedback on selection
- ✅ Auto-dismiss after emoji selection
- ✅ Matches Figma design with proper styling

### 3. **Updated Bottom Sheet** (`AddEventBottomSheet.swift`)
Complete redesign to match Figma specifications:

#### **State 1: Initial View**
- Input field with emoji placeholder icon
- Placeholder text: "eg: last cigarette, no coffee"
- "Started on" section with date and time buttons
- "Image (for widget)" section with "Select" button
- Save button (disabled until emoji + title filled)
- Cancel button

#### **State 2: Emoji Picker**
- Opens when tapping emoji placeholder
- Full emoji grid with search
- Closes automatically after selection

#### **State 3: With Selected Data**
- Shows selected emoji + event title in input field
- Selected image preview (54x54 square with rounded corners)
- "Change image" button replaces "Select"
- Save button enabled when emoji and title are filled

#### **Features**
- ✅ Emoji selection opens full emoji picker
- ✅ Image picker with 1:1 aspect ratio enforcement
- ✅ Image cropping to square if needed
- ✅ Date/Time picker sheets
- ✅ Proper validation (requires emoji + title)
- ✅ Haptic feedback
- ✅ Light mode only

### 4. **Image Picker Component**
- ✅ `ImagePicker` struct using UIImagePickerController
- ✅ Supports photo library selection
- ✅ Optional square aspect ratio enforcement
- ✅ Auto-crop to square (1:1) when required
- ✅ Image editing mode enabled for square selection

### 5. **Date Picker Sheet**
- ✅ Separate sheet for date selection
- ✅ Separate sheet for time selection
- ✅ Clean UI with "Done" button

### 6. **Widget Updates** (`WidgetSinced2.swift` & `SinceWidget.swift`)
Major visual enhancement:

#### **Without Image**
- Clean white background
- Emoji at top-left
- Relative time (large, semibold)
- Caption with start date

#### **With Image**
- ✅ Image fills entire widget background (1:1 aspect)
- ✅ Dark gradient overlay at bottom for text readability
- ✅ Text color changes to white for better contrast
- ✅ Emoji remains visible at top
- ✅ Time and caption in white text

### 7. **CreateEventView Updates**
Updated to use new emoji picker and image selection:
- ✅ Replaced emoji grid with button that opens emoji picker
- ✅ Added image selection section
- ✅ Shows image preview when selected
- ✅ Saves image data with event
- ✅ Validation requires both emoji and title

## Design Specifications (from Figma)

### Colors
- Primary Green: `#00621a`
- Blue Links: `#0881f4`
- Placeholder Gray: `#b5b5b8`
- Text Dark: `#2e2e2e`
- Text Light: `#a5a3a5`
- Background Light: `#f7f7f7`
- Light Gray: `#f3f3f3`
- Disabled Button: `#a6a6a6`

### Typography
- Title: 20pt, Semibold, -0.8 tracking
- Input Text: 16pt, Medium, -0.64 tracking
- Button Text: 16pt, Bold, -0.64 tracking
- Small Button: 12pt, Semibold, -0.48 tracking
- Caption: 10pt

### Layout
- Bottom sheet height: 417px
- Bottom sheet corner radius: 24px
- Input field height: 58px
- Input field corner radius: 12px
- Button height: 48px
- Button corner radius: 50px (pill shape)
- Image preview: 54x54px, 8px corner radius
- Emoji size in input: 23.04pt
- Emoji size in picker: 32pt

## User Flow

1. **Add Event**
   - User taps "+" button
   - Bottom sheet appears with emoji placeholder

2. **Select Emoji**
   - User taps emoji placeholder
   - Emoji picker sheet opens
   - User can search or scroll
   - User taps emoji → picker closes
   - Emoji appears in input field

3. **Enter Event Name**
   - User types event name (e.g., "Last coffee")
   - Title appears next to emoji

4. **Optional: Select Image**
   - User taps "Select" button
   - Photo library opens
   - User selects image (can crop to 1:1)
   - Image preview appears (54x54)
   - Button changes to "Change image"

5. **Set Date/Time**
   - User can adjust start date and time
   - Default is current date/time

6. **Save**
   - User taps "Save" button (enabled only when emoji + title filled)
   - Event saved with emoji, title, date, and optional image
   - Widget displays event with image as background

## Widget Behavior

### Small (1:1) Widget
- Only size available to users
- Shows one event at a time
- User can configure which event to display

### With Image
- Image fills entire widget
- Dark gradient overlay for text legibility
- White text for better contrast
- Emoji, time, and date all visible

### Without Image
- Clean light background
- Dark text
- Same layout and information

## Technical Implementation

### Image Storage
- Images stored as `Data` using JPEG compression (0.8 quality)
- Shared via App Group container for widget access
- Stored in `SinceEvent` model

### Image Requirements
- 1:1 aspect ratio (square)
- Auto-cropped if user selects non-square image
- Optional - events work without images

### Performance
- Images compressed to balance quality and size
- Widget updates respect timeline policy
- Image loading optimized with `UIImage(data:)`

## Files Modified

1. `/Sinced2/Models/SinceEvent.swift` - Added imageData field
2. `/Sinced2/Views/EmojiPickerView.swift` - NEW: Emoji picker view
3. `/Sinced2/Views/AddEventBottomSheet.swift` - Complete redesign
4. `/Sinced2/Views/CreateEventView.swift` - Updated for new emoji/image flow
5. `/WidgetSinced2/WidgetSinced2.swift` - Widget UI with image support
6. `/SinceWidget/SinceWidget.swift` - Widget UI with image support

## Testing Checklist

- [ ] Add event without image - works correctly
- [ ] Add event with image - image appears in widget
- [ ] Change event image - updates in widget
- [ ] Emoji picker search - filters correctly
- [ ] Non-square image - auto-crops to square
- [ ] Widget displays image properly in light mode
- [ ] Text readable on dark images (gradient overlay)
- [ ] Widget updates when event changed
- [ ] Multiple events - correct image for each

## Notes

- App is locked to light mode only (no dark mode)
- Widget only supports small (1:1) size
- Images are optional - events work without them
- Image picker allows editing/cropping before selection
- All haptic feedback included for better UX

## References

- Figma Design: [Link provided by user](https://www.figma.com/design/ACxFE0EsqmsdxhvMuZRFzc/MasterFile-Personal?node-id=184-706&m=dev)
- Three states shown in Figma:
  1. Empty state with placeholder
  2. Emoji picker view
  3. Filled state with image

