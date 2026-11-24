MYCROP — MASTER DEVELOPMENT PROMPT

Complete Flutter Application Specification — FINAL REVISED VERSION

Project: MYCROP
Framework: Flutter / Dart
Development environment: Cursor
Target platforms: iOS and Android
Architecture: Modular, feature-first, maintainable and testable
Primary interface: Mobile-first, portrait-oriented
Development phase: Functional prototype, ready for real device testing
Backend: None
Authentication: None
Internet connection: Not required for document editing
Main language: Italian
Future localization: English, Spanish, French, German and Portuguese

⸻

1. YOUR ROLE AND RESPONSIBILITIES

Act as an expert team consisting of:

* Senior Flutter developer.
* Mobile application architect.
* iOS and Android engineer.
* Image-processing specialist.
* PDF-processing specialist.
* Mobile UX/UI designer.
* Animation engineer.
* Software quality assurance engineer.

Your task is to create a complete, functional and maintainable Flutter application called MYCROP.

The application must perform real image and PDF manipulation.

Do not build a static graphic simulation or an interface with buttons that do nothing.

All core editing operations must produce mathematically correct results.

Prioritize functional correctness, usability, performance and clear architecture.

Use current stable Flutter and Dart versions compatible with the development environment.

Before selecting third-party libraries, verify their maintained status, licensing, platform support and compatibility.

Do not rely on deprecated or abandoned packages.

Implement the application incrementally, testing each milestone before proceeding.

When a technical problem occurs, investigate its cause rather than replacing a feature with a visual workaround.

⸻

2. PRODUCT CONCEPT

MYCROP is an image and PDF editing application designed to remove unwanted internal portions of visual content.

Its distinctive feature is not ordinary edge cropping.

Instead, MYCROP removes a complete internal strip and automatically joins the remaining portions.

Example of horizontal removal:

Original content:

+----------------------+
|                      |
|      SECTION A       |
|                      |
+----------------------+
|                      |
|   UNWANTED STRIP     |
|                      |
+----------------------+
|                      |
|      SECTION C       |
|                      |
+----------------------+

After removal:

+----------------------+
|                      |
|      SECTION A       |
|                      |
|      SECTION C       |
|                      |
+----------------------+

The selected strip disappears completely.

The upper and lower preserved portions become adjacent without empty space.

For vertical cutting, the same logic applies horizontally.

Original:

LEFT | UNWANTED | RIGHT

Result:

LEFT | RIGHT

The preserved content must not be stretched, redesigned, compressed or distorted.

The user must be able to repeat the operation multiple times on the same image or PDF page.

Core workflow:

LOAD → SELECT → REMOVE → JOIN → REPEAT → SAVE.

⸻

3. INITIAL VERSION SCOPE

Implement all the following:

1. Initial home screen.
2. Import image.
3. Import PDF.
4. Interactive editing workspace.
5. Horizontal strip selection.
6. Vertical strip selection.
7. Two independently adjustable cutting lines.
8. Movable cutting handles A and B.
9. Long-press handle repositioning.
10. Zoom slider.
11. Pinch zoom.
12. Image/document panning.
13. Horizontal strip removal.
14. Vertical strip removal.
15. Automatic recombination of preserved portions.
16. Continuous cutting.
17. Automatic reappearance of cutting lines.
18. Selection visibility toggle.
19. Undo.
20. Redo.
21. SMASH animation toggle.
22. Official SMASH character animation.
23. Image saving.
24. Image sharing.
25. PDF import and rendering.
26. Multi-page PDF navigation.
27. PDF editing.
28. Exactly four PDF page-layout modes.
29. Independent layout settings for each PDF page.
30. PDF export.
31. PDF sharing.
32. Local preference persistence.
33. Error handling.
34. Unit and integration tests.

Do not implement during the first phase:

* Accounts.
* Registration.
* Firebase.
* Cloud storage.
* Payments.
* Subscriptions.
* Advertising.
* Online editing.
* Social features.
* AI processing.
* OCR.
* Marketplace features.

All editing must work locally without requiring an account or internet access.

⸻

4. DEVELOPMENT ARCHITECTURE

Use a modular feature-first architecture.

Separate:

* Presentation layer.
* Application state and orchestration.
* Domain models and operations.
* File import/export.
* Image processing.
* PDF processing.
* Animation rendering.
* Persistence.
* Testing.

Recommended folder structure:

lib/
  main.dart
  app/
    app.dart
    app_router.dart
    app_theme.dart
    app_config.dart
  core/
    constants/
    errors/
    extensions/
    utilities/
    services/
    widgets/
  features/
    home/
      presentation/
        home_screen.dart
        widgets/
    editor/
      domain/
        models/
        geometry/
        operations/
      application/
        editor_controller.dart
        editor_state.dart
        history_manager.dart
        selection_controller.dart
        viewport_controller.dart
      presentation/
        editor_screen.dart
        widgets/
        painters/
        gestures/
    image_processing/
      domain/
      services/
      data/
    pdf_processing/
      domain/
        pdf_document_model.dart
        pdf_page_model.dart
        pdf_layout_config.dart
      application/
      services/
      presentation/
        widgets/
    animation/
      domain/
      application/
      presentation/
      services/
    export/
      domain/
      application/
      services/
    settings/
      application/
      data/
assets/
  branding/
  home/
  icons/
  characters/
    smash/
      frames/
test/
  geometry/
  cutting/
  history/
  pdf/
  animation/
integration_test/

The exact names may be adjusted, but responsibilities must remain separated.

Do not write the image-processing algorithm directly inside Flutter widgets.

Do not mix character-animation logic with the mathematical cutting engine.

Use immutable state models when practical.

⸻

5. TECHNOLOGY AND DEPENDENCIES

Evaluate appropriate maintained Flutter packages for:

* File picking.
* Image decoding and encoding.
* PDF rendering.
* PDF generation and page composition.
* Sharing.
* Local preferences.
* File paths and temporary storage.
* State management.

Possible candidates include:

file_picker
image
pdfx
pdfrx
pdf
share_plus
path_provider
shared_preferences
flutter_riverpod

These are candidates, not mandatory dependencies.

Verify current versions, licensing and capabilities before installing them.

In particular, evaluate whether the selected PDF tooling can preserve original unmodified PDF pages while replacing edited pages.

If it cannot, explain the limitation and implement a reliable alternative.

Avoid unnecessary dependencies.

Do not introduce Firebase or a server.

⸻

6. DOCUMENT DATA MODEL

The application must support two main document types:

ImageDocument
PdfDocument

Both must use a shared cutting model.

A document should track:

* Unique identifier.
* Original file reference.
* Document type.
* Original dimensions.
* Current edited dimensions.
* Current orientation.
* Current cutting coordinates.
* Current viewport transformation.
* History of operations.
* Undo/Redo state.
* Modified state.
* Export configuration.

The original file must remain untouched.

Every operation should be reproducible from the original and its edit history.

For PDF documents, additionally store:

* Total page count.
* Current page index.
* Original dimensions of each page.
* Original page orientation.
* Independent cutting history per page.
* Independent page-layout configuration.
* Modified/unmodified status per page.
* Edited content dimensions per page.
* Content positioning offsets per page.

A PDF may contain pages of completely different dimensions.

Never assume that every PDF is A4.

Never assume that all pages in one PDF share the same size.

⸻

7. IMAGE CUTTING ENGINE

Implement real pixel-based strip removal.

The cutting engine must work independently from the UI and animations.

For horizontal cuts:

top = min(A, B)
bottom = max(A, B)
removedHeight = bottom - top
newHeight = originalHeight - removedHeight

Construct the new image by vertically joining:

pixels above top
+
pixels below bottom

For vertical cuts:

left = min(A, B)
right = max(A, B)
removedWidth = right - left
newWidth = originalWidth - removedWidth

Construct the new image by horizontally joining:

pixels left of left
+
pixels right of right

Requirements:

* No unwanted blank gaps.
* No scaling.
* No stretching.
* No invented pixels.
* No reconstructed content.
* Correct resulting dimensions.
* Correct boundary handling.
* Stable results across multiple sequential cuts.

The preserved pixels must remain exact whenever the source and output format support lossless processing.

Validate all coordinates.

Reject invalid cuts.

A cut must not leave an image with zero width or height.

Do not process the full-resolution image continuously while a handle is being dragged.

Only perform the final image operation when the user confirms the cut.

⸻

8. NON-DESTRUCTIVE EDITING

Never overwrite the imported original.

Represent each edit as an operation.

Each cut operation records:

* Orientation.
* Cutting coordinates A and B.
* Dimensions before the cut.
* Dimensions after the cut.
* Page identifier if editing a PDF.
* Operation order.

Undo must restore the previous state.

Redo must restore the next state.

When a new operation is performed after Undo, invalidate the incompatible Redo branch.

Avoid storing unlimited full-resolution copies in RAM.

Use operation history, caching and selective checkpoints.

PDF page-layout changes and custom-position changes must also be reversible.

⸻

9. HOME SCREEN

Build the home screen using the approved visual reference that will be provided.

The home screen contains:

* MYCROP brand.
* Editor heading.
* Futuristic demonstration card.
* Before/after example.
* Official SMASH character giving a thumbs-up.
* Short product explanation.
* Load Image button.
* Load PDF button.

The demonstration card must show the application’s real purpose.

The BEFORE image has a selected internal strip.

The AFTER image must be the mathematically correct result of removing exactly that strip.

The two previews must represent the same source image.

Do not generate an unrelated or approximate after image.

Use the approved dark futuristic visual style.

Home text:

Rimuovi ciò che non serve.

Seleziona una porzione, eliminala e unisci automaticamente il resto.

Buttons:

Load Image

Load PDF

Supporting text:

Scegli un’immagine o un documento PDF per iniziare

The buttons must be real and functional.

Load Image opens the appropriate picker.

Load PDF opens the document picker.

After successful import, open the main editor.

⸻

10. MAIN EDITOR — GENERAL LAYOUT

Use the supplied official editor reference.

The editor must resemble the approved layout and retain its functional hierarchy.

At the top:

* MYCROP brand.
* Condividi.
* Salva.
* Undo.
* Redo.
* Zoom indicator.
* Zoom slider.

Center:

* Large editing viewport.
* Image or PDF page.
* Two cutting lines.
* A and B handles.
* Translucent selection overlay.

Bottom:

* Large red Rimuovi porzione button.
* Orizzontale.
* Verticale.
* SMASH toggle.
* Load Image.
* Load PDF.

The primary remove button occupies its own row.

Below it, Orizzontale, Verticale and SMASH share a compact row.

Load Image and Load PDF remain clearly visible and occupy the final row.

Do not remove or reduce the importance of these import buttons to make space for optional effects.

The document must occupy the maximum practical available area.

Avoid decorative bars that unnecessarily reduce the viewport.

⸻

11. RESPONSIVE DISPLAY

Design primarily for modern portrait smartphones.

Reference a realistic iPhone logical viewport, such as approximately:

393 × 852 logical points

Also support smaller and larger devices.

Do not change the phone’s proportions to fit the UI.

Do not deform content.

A 9:16 image must retain its actual aspect ratio.

A PDF page must retain its actual aspect ratio.

The main document should be displayed using a content-fit calculation.

At zoom 1.0x, the complete document must fit inside the viewport.

Calculate:

fitScale = min(
  viewportWidth / contentWidth,
  viewportHeight / contentHeight
)
effectiveScale = fitScale * zoomFactor

Zoom factor 1.0 represents the fit-to-viewport state.

Do not add an unnecessary permanent Fit button.

⸻

12. ZOOM AND PAN

Provide:

* Zoom slider.
* Numerical zoom indicator.
* Pinch-to-zoom.
* Panning when zoomed.

Suggested initial zoom range:

1.0x to 5.0x

Keep the range configurable.

At 1.0x:

* Show the entire document.
* Center it in the viewport.
* Preserve aspect ratio.

Above 1.0x:

* Allow one-finger dragging to move the document.
* Allow pinch gestures.
* Keep movement smooth.
* Respect appropriate pan limits.

The cutting coordinates must remain attached to the content when the user zooms or pans.

Zooming must never change the actual selected cutting positions.

Use a dedicated coordinate transformation service.

⸻

13. CUTTING LINES A AND B

The selection consists of two thin red boundary lines.

Between them, display a dark translucent overlay.

The content underneath must remain visible.

Initial overlay opacity should be configurable, approximately 35–50%.

Do not display a permanent text label inside the selected region.

The red lines and dark overlay must make the removal region understandable without explanatory text.

Line A and line B must be independent.

Dragging A must not move B.

Dragging B must not move A.

⸻

14. HORIZONTAL CUTTING MODE

For horizontal cutting:

* Two horizontal red lines.
* A initially on the left.
* B initially on the right.
* Red, horizontally oriented rounded-rectangle handles.
* Visible vertical movement arrows.
* Independent up/down movement.

The selected strip spans the full width of the document content.

The handle shape should remain horizontal.

Do not rotate the handles vertically in horizontal mode.

⸻

15. VERTICAL CUTTING MODE

For vertical cutting:

* Two vertical red lines.
* A initially positioned near the top of its line.
* B initially positioned near the bottom of its line.
* Handles change to a vertical shape.
* Visible horizontal movement arrows.
* Independent left/right movement.

The selected strip spans the full height of the document content.

Maintain readable A and B labels.

⸻

16. ADVANCED HANDLE GESTURES

Every handle supports two different movement types.

Normal drag

Moves the cutting line.

Horizontal mode:

* Drag up/down.

Vertical mode:

* Drag left/right.

Long press and drag

Moves the handle along its own line without moving the line.

Horizontal mode:

* Move handle left/right.

Vertical mode:

* Move handle up/down.

Long press must clearly activate the secondary gesture.

Use a subtle visual highlight or direction indicator.

Implement magnetic positioning.

Default positions:

* Horizontal A left.
* Horizontal B right.
* Vertical A top.
* Vertical B bottom.

When the user moves a handle close to its default position, apply gentle snapping.

Double-tapping a handle resets only its position along the line.

Double tap must not move the cutting boundary itself.

When loading a new document, reset the handle positions.

During consecutive cuts, preserve valid handle preferences where possible.

Use generous touch-target dimensions.

Prevent gesture conflicts.

⸻

17. ORIENTATION AND VISIBILITY TOGGLES

The editor has exactly three selection states:

horizontal
vertical
none

The Orizzontale and Verticale buttons function as mode selectors and visibility toggles.

Rules:

* Tap Orizzontale when inactive: activate horizontal selection.
* Tap Orizzontale when already active: hide selection.
* Tap Orizzontale again: restore horizontal selection.
* Tap Verticale when inactive: activate vertical selection.
* Tap Verticale when already active: hide selection.
* Tap Verticale again: restore vertical selection.

Changing orientation replaces the previous selection.

Never show horizontal and vertical selections simultaneously.

When selection is hidden:

* Hide A/B.
* Hide red lines.
* Hide dark overlay.
* Show the document cleanly.
* Disable Rimuovi porzione.

Manually hiding the selection must not erase previously configured coordinates.

Reactivating the same selection should restore its previous position when still valid.

⸻

18. CONTINUOUS CUTTING — OFFICIAL BEHAVIOR

MYCROP must make repeated cutting extremely fast.

The user must not have to reactivate the cutting tool manually after each removal.

When an image or PDF page is loaded:

* Show horizontal selection automatically.

After a successful cut:

1. Temporarily hide the lines A/B.
2. Execute the mathematical removal operation.
3. Display the appropriate animation.
4. Join the preserved portions completely.
5. Show the joined result cleanly.
6. Wait approximately 600 milliseconds.
7. Automatically show a new selection.
8. Preserve the current orientation.
9. Place the new selection at useful default coordinates.
10. Allow the next cut immediately.

The configurable reappearance interval is:

500–800 milliseconds.

Use 600 milliseconds initially.

Critical synchronization rule

The timer must start after the preserved portions have fully joined.

It must never start when the Remove button is pressed.

This is true whether SMASH is enabled or disabled.

If a modal PDF layout dialog is active, suspend automatic selection reappearance until the dialog closes.

Do not trigger the selection underneath an active modal panel.

⸻

19. REMOVE PORTION BUTTON

The main action is:

Rimuovi porzione

This button must be visually prominent.

On activation:

1. Validate selection.
2. Prevent duplicate commands.
3. Temporarily lock conflicting gestures.
4. Calculate the result.
5. Prepare animation.
6. Perform visual removal and joining.
7. Commit the operation safely.
8. Restore the editor.
9. Start the selection reappearance sequence.

The animation must not be responsible for creating the final pixels.

The actual edit and the visual effect are separate systems.

⸻

20. SMASH — OFFICIAL CHARACTER

SMASH is the original MYCROP robotic character.

Appearance:

* Red armored robot.
* Dark mechanical joints.
* Large mechanical fists.
* Cyan luminous eyes.
* Cyan glowing circular chest core.

Use the original approved transparent PNG animation frames.

The asset ZIP will be supplied separately.

Do not redesign or replace the character.

Do not generate alternative frames if official frames are available.

SMASH is enabled by default.

Persist the ON/OFF preference locally.

In the editor, the SMASH control includes:

* Original face icon.
* Label SMASH.
* Standard toggle switch.

No additional ON/OFF text is needed.

⸻

21. SMASH — UNIVERSAL MOVEMENT RULES

SMASH always enters from the left.

SMASH always exits to the right.

The entire character animation must stay inside the document editing viewport.

It must never run over:

* The phone frame.
* The top toolbar.
* The bottom control buttons.
* Other areas outside the designated animation viewport.

Use clipping.

The character begins completely outside the left boundary of the viewport and ends completely outside the right boundary.

Entry and exit must look natural.

The punch must land on the geometric center of the selected strip.

The actual fist contact point must be aligned with the selected epicenter, not simply the center of the robot’s image frame.

Keep the character’s aspect ratio and original animation appearance.

⸻

22. SMASH — HORIZONTAL CUT

For horizontal cutting, calculate:

impactX = contentWidth / 2
impactY = (cutA + cutB) / 2

Convert these coordinates to viewport-local coordinates.

SMASH enters from the left at the correct vertical position for the punch to reach the epicenter.

If the selected strip is higher, SMASH must enter higher.

If the strip is lower, SMASH must enter lower.

Sequence:

1. SMASH enters from left.
2. Runs toward the selected strip’s epicenter.
3. Performs the official punch animation.
4. The fist hits the epicenter.
5. The selected strip breaks into fragments.
6. The selected strip disappears.
7. The upper retained image portion moves downward.
8. The lower retained image portion moves upward.
9. Both portions join perfectly.
10. SMASH continues the official animation sequence.
11. SMASH exits entirely to the right.
12. The selection automatically returns after the specified delay.

Only the selected strip may be destroyed.

Content outside the selected region must remain intact.

⸻

23. SMASH — VERTICAL CUT

For vertical cutting:

impactX = (cutA + cutB) / 2
impactY = contentHeight / 2

The movement trajectory normally remains centered vertically.

SMASH:

1. Enters from the left.
2. Runs horizontally toward the vertical strip’s epicenter.
3. Delivers the punch.
4. Destroys the selected vertical strip.
5. The left retained portion moves right.
6. The right retained portion moves left.
7. Both portions join perfectly.
8. SMASH exits to the right.
9. The selection reappears automatically after the configured delay.

The impact point must shift horizontally according to the position of the selected band.

⸻

24. SMASH ANIMATION ORCHESTRATION

Use separate animation phases:

idle
entering
running
approaching
impact
destruction
joining
celebration
exiting
completed

Some phases may visually overlap if required to reproduce the original approved sequence.

The official PNG frames determine the character’s animation.

Use configurable metadata for:

* Frame duration.
* Animation sequence.
* Movement speed.
* Scale.
* Impact anchor.
* Entry position.
* Exit position.
* Joining duration.

Do not use artificial replacement animations that visually alter SMASH.

Do not flip the character horizontally.

Do not invent extra effects outside the selected region.

All animation must be clipped to the content viewport.

For a cut near the top or bottom, adjust placement or character scale while keeping the fist accurately aligned with the epicenter.

If exact alignment cannot be achieved without clipping, report the limitation instead of silently moving the punch to an incorrect position.

⸻

25. SMASH OFF — STANDARD REMOVAL

When SMASH is disabled:

1. Hide selection.
2. Remove the strip.
3. Animate the preserved portions approaching.
4. Join them precisely.
5. Display the clean result.
6. Wait approximately 600 milliseconds after joining.
7. Restore a new selection.

No character appears.

The final result must be identical with SMASH ON and SMASH OFF.

Only the visual experience changes.

⸻

26. UNDO AND REDO

Use two consistent rectangular buttons.

Undo and Redo must be visibly distinguishable.

Do not use a refresh-looking icon for Redo.

Support:

* Reversing cuts.
* Reapplying cuts.
* Multiple sequential operations.
* PDF page-layout changes.
* PDF custom-position changes.

When Undo is performed:

* Restore previous document state.
* Update dimensions.
* Update selection validity.
* Do not unnecessarily replay SMASH.

Redo restores the next saved state.

After a new edit, invalidate the incompatible Redo branch.

The original imported document must remain available throughout the editing session.

⸻

27. PDF IMPORT AND MULTIPAGE SUPPORT

MYCROP must accept PDF documents regardless of page size.

Examples:

* A4.
* A3.
* A5.
* US Letter.
* Legal.
* Receipts.
* Custom sizes.
* Mixed-size documents.
* Landscape pages.
* Portrait pages.
* Scanned pages.
* Text-based pages.
* Pages containing tables or images.

Users must be allowed to import PDFs containing selectable text.

The app does not need to preserve editable or selectable text in modified rasterized pages.

However, the result must preserve the visible page content outside the removed strips.

The application must clearly communicate that modified pages may be rasterized and that digital signatures or other PDF-native features may not remain valid.

Never modify the original source file.

Do not bypass PDF permissions or passwords.

⸻

28. PDF PAGE NAVIGATION

Display a compact page navigator:

← Pag. 2 di 4 →

Rules:

* Left arrow: previous page.
* Right arrow: next page.
* Disable arrows at document boundaries.
* Keep page edits when navigating.
* Preserve each page’s individual layout.
* Adapt the current page to the available viewport.

The navigator must be compact.

Do not introduce a permanent side panel containing thumbnails.

The document must occupy the maximum available editing area.

⸻

29. PDF LAYOUT — EXACTLY FOUR MODES

MYCROP supports exactly four PDF layout modes.

Display them in this precise order:

1. Centrato
2. In alto
3. Riduci pagina
4. Personalizza posizione

Do not add other layout modes.

These modes apply to the edited content after the strip has been removed and the retained portions have joined.

The layout system must not repeat or alter the cutting operation.

MODE 1 — CENTRATO

Keep the original physical PDF page dimensions.

Do not change the size of the edited content.

Place the joined content at the center of the original page.

For horizontal cuts:

* Keep the original page width and height.
* Center the shortened content vertically.
* Distribute blank space above and below.

For vertical cuts:

* Keep original page dimensions.
* Center the narrower content horizontally.
* Distribute blank space on both sides.

If cuts have reduced both width and height, center along both axes.

No scaling or deformation is permitted.

MODE 2 — IN ALTO

Keep the original physical PDF page dimensions.

Do not scale the edited content.

For horizontal cuts:

* Position the content at the top.
* Leave unused white space below.

For vertical cuts:

* Use the equivalent start-edge positioning.
* Align the content to the left.
* Leave unused white space to the right.

For content reduced in both dimensions, align it to the top-left corner.

The user-facing label remains In alto.

Do not add a fifth “Left” mode.

MODE 3 — RIDUCI PAGINA

Actually reduce the PDF page dimensions to match the edited content.

Horizontal cutting:

* Page height becomes shorter.
* Page width remains unchanged unless previously reduced.

Vertical cutting:

* Page width becomes narrower.
* Page height remains unchanged unless previously reduced.

Multiple cuts may reduce both dimensions.

Do not simply shrink the content within the original PDF page.

The PDF page itself must become smaller.

Do not stretch or compress the edited content.

Preserve the correct relationship between pixel dimensions and PDF page coordinates.

MODE 4 — PERSONALIZZA POSIZIONE

This mode changes position only.

It must never change content size.

Keep the original PDF page dimensions.

Keep the edited content at its exact post-cut dimensions and scale.

The user can freely move the already-joined content inside the original page using direct touch dragging.

Official interaction:

1. User selects Personalizza posizione.
2. Open positioning mode.
3. Show the original page boundaries.
4. Show the joined content inside the page.
5. Allow direct one-finger dragging of the entire content.
6. Update the position preview immediately.
7. Keep the entire content within valid page boundaries.
8. When the user is satisfied, show a clearly visible red button:
    Conferma posizione
9. When tapped, commit the position.
10. Return to the normal PDF editor.

The user may move the content vertically or horizontally within valid bounds.

Do not resize the content.

Do not show scaling handles.

Do not use corner handles that imply resizing.

Do not enable pinch-to-resize.

Do not introduce four directional arrow buttons as the primary positioning method.

Do not modify the actual PDF page dimensions.

Do not rotate the content.

Do not change its aspect ratio.

The entire joined content must move as a single unit.

Provide a cancel action that discards unconfirmed positioning changes.

Conferma posizione is the confirmation action for this mode.

The top-level Salva button remains dedicated to saving/exporting.

Do not repurpose Salva for positioning.

Custom positioning must support Undo/Redo.

⸻

30. PDF LAYOUT — FIRST CUT WORKFLOW

After the first successful PDF cut:

1. Complete the actual strip removal.
2. Complete joining of the preserved content.
3. Display the result.
4. Open a temporary bottom-sheet layout panel.
5. Present the four modes.
6. Allow previewing each mode.
7. Let the user select the preferred result.
8. Confirm the selection.
9. Close the layout panel.
10. Restore the normal editor with maximum available document space.

For Centrato, In alto and Riduci pagina, use:

Applica e continua

For Personalizza posizione:

* Enter direct manipulation mode.
* Allow dragging.
* Use Conferma posizione.

Use In alto as the initial suggestion unless a saved preference exists.

Do not ask the user to choose a layout after every subsequent cut.

Store the selected layout as the current page’s preference.

The app may suggest the last used mode for newly modified pages.

A previously customized page must retain its own configuration.

When a layout panel is open, suspend the automatic selection reappearance.

After confirmation and closing of the panel, show the next valid cutting selection.

⸻

31. PDF LAYOUT — COMPACT BUTTON

Add a compact button labeled:

Layout PDF

It must be visible when editing a PDF.

It must not appear unnecessarily when editing an ordinary image.

Place it near the PDF page navigator or another space-efficient location.

The button must not consume a large permanent row.

When tapped:

* Open the temporary layout panel.
* Display the current page’s four modes.
* Highlight the selected mode.
* Allow changing the mode.
* Allow confirmation.

After the user confirms:

* Close the panel completely.
* Restore the full editor viewport.
* Leave only the compact Layout PDF button visible.

Do not maintain a permanent layout drawer, sidebar or thumbnail column.

The PDF page must remain the visual priority.

⸻

32. PDF LAYOUT — PAGE INDEPENDENCE

Every PDF page stores its own layout setting.

Example:

Page 1: Centrato
Page 2: In alto
Page 3: Riduci pagina
Page 4: Personalizza posizione

Changing one page must not automatically change other pages.

Each page must preserve:

* Its original dimensions.
* Its edited content dimensions.
* Its cutting history.
* Its selected layout mode.
* Its custom positioning coordinates when applicable.

Provide a clearly separate optional action to apply a selected layout to multiple modified pages.

Such an action must require explicit confirmation.

Do not silently overwrite other pages’ settings.

Do not add permanent page thumbnails to the editor.

If a page-management view is required, make it temporary.

⸻

33. PDF LAYOUT DATA SEPARATION

Maintain separate data for:

1. Original PDF page dimensions.
2. Actual edited content dimensions.
3. Output PDF page dimensions.
4. Content positioning within the output page.
5. Current viewport zoom and pan.

Example:

originalPageWidth
originalPageHeight
editedContentWidth
editedContentHeight
outputPageWidth
outputPageHeight
contentOffsetX
contentOffsetY
viewportZoom
viewportPanX
viewportPanY

Changing page layout must not destroy the underlying edited content.

Do not repeatedly incorporate blank page margins into the editable image data.

Subsequent cuts must apply to the actual joined content, not to temporary white-space padding added by the PDF layout system.

This requirement is essential for reliable consecutive cuts.

⸻

34. PDF RENDERING AND PROCESSING

For PDF editing, use a rendering pipeline that can convert page content into a suitable image representation.

The rendering resolution must balance quality, file size and memory use.

Do not assume screen-resolution previews are sufficient for final export.

Maintain distinct preview and export quality where appropriate.

Render pages lazily.

Do not load an entire large PDF into full-resolution image buffers simultaneously.

Cache recent previews.

Respect page rotation and dimensions.

Modified pages may be rasterized.

Unmodified pages should preferably retain their original quality and PDF-native structure where the selected library supports it.

If the implementation cannot preserve unmodified pages without rasterization, document this limitation before selecting the export strategy.

⸻

35. PDF EXPORT

When saving a PDF:

* Preserve page order.
* Preserve page count unless the user explicitly deletes pages in a future feature.
* Apply each modified page’s independent layout.
* Use correct output page dimensions.
* Preserve unmodified pages where supported.
* Avoid unnecessary compression.
* Prevent unexpected clipping.
* Produce a valid readable PDF.

A document containing differently sized pages must remain valid.

The exported result must be verified after generation.

Do not overwrite the imported original without explicit authorization.

⸻

36. SAVE AND SHARE

The top-level buttons are:

Salva

Condividi

Their responsibilities must remain separate.

Salva

Saves the edited output.

For images, support:

* PNG.
* JPEG.

For PDF documents:

* Export a PDF containing the complete document.

Provide an appropriate system save destination workflow.

Condividi

Opens the native system share sheet with the generated output.

Do not use Condividi as a settings menu.

Do not use Salva as an application options menu.

Do not display fake success notifications.

Only report success after successful file creation or an appropriate completed platform operation.

⸻

37. IMAGE AND PDF QUALITY

Preserve as much source quality as technically possible.

For images:

* Avoid unnecessary recompression.
* Preserve alpha transparency for PNG.
* Respect image orientation metadata.
* Maintain original pixel resolution outside removed strips.

For PDF:

* Use a sufficient rendering resolution.
* Respect the original page’s dimensions.
* Preserve visual content outside cuts.
* Do not claim modified rasterized text remains selectable.

Prevent unnecessary re-encoding during previews.

⸻

38. PERFORMANCE AND MEMORY MANAGEMENT

The app must handle large screenshots and multipage PDF documents.

Implement:

* Asynchronous decoding.
* Background processing where appropriate.
* Lazy PDF rendering.
* Preview caching.
* Memory-conscious image handling.
* Temporary-file cleanup.
* Robust lifecycle handling.

Dragging A/B should not cause repeated full-resolution cutting calculations.

Zooming must remain responsive.

Use repaint isolation and custom painting where useful.

Avoid rebuilding unrelated widgets during gesture updates.

Do not freeze the UI during export.

⸻

39. ERROR HANDLING

Handle the following gracefully:

* Corrupt image files.
* Unsupported formats.
* Invalid PDF.
* Password-protected PDF.
* File-picker cancellation.
* Low memory.
* Invalid cutting coordinates.
* Insufficient document dimensions after cutting.
* Export failures.
* File-system errors.
* Sharing errors.
* App backgrounding during processing.

Use understandable Italian messages.

Do not leave the editor in a partially committed or broken state.

⸻

40. LOCAL PREFERENCES

Store lightweight application preferences locally.

At minimum:

* SMASH enabled/disabled.
* Last used cutting orientation.
* Default PDF layout suggestion.
* Optional animation configuration.
* Other non-sensitive UI preferences.

SMASH should initially be ON.

Do not store entire imported image or PDF files inside key-value preferences.

Do not require an account.

⸻

41. GRAPHIC REFERENCES — CRITICAL INSTRUCTIONS

Official visual references will be supplied separately.

They include:

* Home screen.
* Image editor.
* Vertical selection.
* PDF editor.
* PDF layout selection.
* Custom positioning.
* Multipage PDF examples.
* SMASH animation assets.

These images are explanatory visual references, not an infallible functional specification.

Generated mockups may contain:

* Incorrect text.
* Distorted proportions.
* Duplicated controls.
* Inconsistent button positions.
* Incorrect icons.
* Inaccurate PDF representations.
* Impossible combinations of application states.
* Buttons added by image generation without authorization.
* Visually incorrect document cutting results.
* Incorrect SMASH poses or positioning.

Cursor must intelligently identify and disregard those inconsistencies.

The written requirements in this Master Prompt take precedence over any conflicting graphic.

Do not invent additional functions based solely on accidental elements in a generated mockup.

Do not reproduce visual mistakes as application features.

In particular:

* Do not add arrow controls for PDF custom positioning.
* Do not introduce scaling in Personalizza posizione.
* Do not use Save as a settings button.
* Do not add permanent PDF sidebars.
* Do not permanently reduce the document viewport for decorative purposes.
* Do not treat visually approximate before/after illustrations as the cutting algorithm.
* Do not create an extra PDF layout mode.
* Do not change the approved SMASH behavior.

Recreate the UI using real Flutter widgets.

Do not insert screenshots of the interface as static backgrounds.

Use the supplied illustrations only for their intended graphic purposes.

If a graphic contradicts this specification, implement the specification.

If a significant functional ambiguity remains, document it clearly before inventing new behavior.

⸻

42. OFFICIAL ASSET MANAGEMENT

Prepare a system for future official assets.

Expected files include:

* MYCROP logo.
* Home illustration.
* SMASH face icon.
* SMASH transparent animation frames.
* Other icons.

Keep graphics separate from application logic.

For SMASH, implement a frame manifest describing:

* Frame names.
* Frame order.
* Frame timing.
* Impact anchor.
* Character movement parameters.

Do not assume each PNG has identical visible content bounds.

Preserve transparency.

Do not modify the character’s design.

⸻

43. AUTOMATED TESTS

Implement unit tests for the cutting engine.

Required cases:

1. Horizontal cut.
2. Vertical cut.
3. Reversed A/B coordinates.
4. Multiple consecutive cuts.
5. Exact pixel comparison.
6. Output dimensions.
7. Invalid cut rejection.
8. Undo and Redo.
9. Cutting after zoom/pan.
10. Different source image sizes.

Implement PDF tests:

1. Single-page PDF.
2. Four-page PDF.
3. Mixed page sizes.
4. Landscape pages.
5. Scanned PDF.
6. Text-based PDF.
7. Independent page layouts.
8. PDF export validity.
9. Repeated cuts.
10. Custom positioning without resizing.

Implement gesture tests:

1. Independent A/B movement.
2. Long-press handle movement.
3. Double-tap handle reset.
4. Pinch zoom.
5. Pan.
6. Orientation switching.
7. Selection hiding and reactivation.

Implement SMASH tests:

1. Left entry.
2. Right exit.
3. Horizontal impact alignment.
4. Vertical impact alignment.
5. Viewport clipping.
6. Correct operation sequencing.
7. Automatic A/B reappearance.
8. Identical final pixels with SMASH enabled or disabled.

⸻

44. FULL USER FLOW TESTS

Scenario A — Image editing

1. Open app.
2. Load image.
3. View horizontal selection.
4. Move A.
5. Move B.
6. Remove strip.
7. Watch the joining animation.
8. Wait approximately 600 ms.
9. Confirm new selection appears.
10. Make another cut.
11. Undo.
12. Redo.
13. Save PNG.
14. Share.

Scenario B — Vertical cutting

1. Load image.
2. Select Verticale.
3. Position A/B.
4. Perform vertical cut.
5. Verify left/right joining.
6. Perform another vertical cut.
7. Save.

Scenario C — Selection visibility

1. Load image.
2. Activate Orizzontale.
3. Tap Orizzontale again.
4. Verify selection disappears.
5. Tap Orizzontale again.
6. Verify selection returns.
7. Switch to Verticale.
8. Verify horizontal selection disappears.
9. Tap Verticale again.
10. Verify clean image state.

Scenario D — SMASH

1. Enable SMASH.
2. Select a high horizontal band.
3. Perform cut.
4. Confirm SMASH enters from left at the appropriate height.
5. Confirm punch hits the epicenter.
6. Confirm selected strip destruction.
7. Confirm preserved sections join.
8. Confirm SMASH exits right.
9. Confirm A/B reappears automatically.
10. Disable SMASH.
11. Repeat with another cut.
12. Confirm correct joining without character.

Scenario E — PDF layout

1. Load four-page PDF.
2. Navigate to Page 2.
3. Select an unwanted strip.
4. Perform cut.
5. Open first-cut layout selection.
6. Choose Centrato.
7. Confirm.
8. Make another cut.
9. Navigate to Page 3.
10. Choose Riduci pagina.
11. Navigate back to Page 2.
12. Verify it remains centered.
13. Export PDF.
14. Verify page order and dimensions.

Scenario F — Custom PDF positioning

1. Load PDF.
2. Perform cut.
3. Select Personalizza posizione.
4. Display the original page boundaries.
5. Drag the joined content.
6. Verify content dimensions never change.
7. Tap Conferma posizione.
8. Verify the position is saved.
9. Undo.
10. Redo.
11. Export PDF.
12. Verify the custom position is correctly preserved.

⸻

45. IMPLEMENTATION MILESTONES

Implement in the following order.

MILESTONE 1 — Flutter foundation

Create the Flutter project.

Implement:

* Architecture.
* Theme.
* Navigation.
* Home screen.
* Working image and PDF pickers.

Verify the application launches on supported devices.

MILESTONE 2 — Image cutting engine

Implement:

* Pure cutting algorithms.
* Geometry models.
* Dimension handling.
* Pixel-preservation tests.

Do not implement SMASH yet.

MILESTONE 3 — Interactive image editor

Implement:

* Main viewport.
* A/B selection.
* Gestures.
* Zoom.
* Pan.
* Orientation.
* Remove action.

MILESTONE 4 — Continuous cutting

Implement:

* Selection reappearance.
* Visibility toggles.
* Multiple cuts.
* Undo/Redo.
* Saving and sharing images.

MILESTONE 5 — PDF import

Implement:

* PDF import.
* Rendering.
* Page navigation.
* Mixed page sizes.
* Per-page state.

MILESTONE 6 — PDF editing and layout

Implement:

* PDF cutting.
* All four layout modes.
* Custom direct-drag positioning.
* Conferma posizione.
* Per-page layout independence.
* PDF export.
* PDF Undo/Redo.

MILESTONE 7 — SMASH

Import the original supplied animation.

Implement:

* Entry from left.
* Geometric epicenter targeting.
* Official punch.
* Selected-region destruction.
* Joining.
* Exit right.
* Automatic selection reappearance.
* ON/OFF toggle.

MILESTONE 8 — Graphics and final refinement

Integrate official UI and graphic assets.

Adjust responsive layout.

Improve performance.

Test on physical iOS and Android devices.

⸻

46. ACCEPTANCE CRITERIA

The application is considered functionally complete for the prototype only when:

* Image import works.
* PDF import works.
* Horizontal cutting works.
* Vertical cutting works.
* A/B handles are independent.
* Zoom and pan work.
* No coordinate drift occurs.
* Real strip removal works.
* Preserved sections join correctly.
* Continuous cutting works.
* Selection visibility toggles work.
* Undo works.
* Redo works.
* SMASH animation can be enabled/disabled.
* SMASH impacts the correct epicenter.
* SMASH stays inside the content viewport.
* PDF multipage navigation works.
* Every PDF page can have a different layout.
* Exactly four PDF layout modes exist.
* Custom positioning moves content without resizing.
* Conferma posizione correctly commits the chosen position.
* Image saving works.
* PDF export works.
* Sharing works.
* No authentication is required.
* The application can edit documents offline.
* Automated tests pass.

Do not declare a milestone finished merely because its interface is visible.

Its actual behavior must be implemented and tested.

⸻

47. IMPORTANT UX PRINCIPLES

MYCROP must feel fast and intuitive.

The main goal is to minimize the number of actions required to remove multiple unwanted strips.

Users should not need tutorials to understand the basic workflow.

The two cutting lines must clearly show what will be removed.

The selected area must remain partially transparent.

The user must always be able to hide the selection and see the clean document.

After cutting, a new selection must return automatically.

PDF layout settings must remain accessible without permanently occupying the workspace.

SMASH must remain a visual enhancement rather than a requirement for editing.

The actual document-processing engine must work independently from animation.

Avoid unnecessary buttons.

Avoid unnecessary dialog boxes.

Do not create additional functions that have not been specified.

The document must always remain the central focus of the application.

⸻

48. FIRST EXECUTION IN CURSOR

Start by inspecting the development environment.

Verify:

* Flutter installation.
* Dart SDK.
* Android toolchain.
* iOS toolchain when available.
* Package compatibility.
* Required permissions.
* Relevant platform limitations.

Then:

1. Create the project architecture.
2. Create the theme and design tokens.
3. Create the home screen.
4. Implement real file import.
5. Create a working editor scaffold.
6. Establish image-processing models.
7. Implement the pure cutting engine.
8. Add geometry unit tests.
9. Run analysis and tests.
10. Report the implementation status.

Do not begin by building every animation and PDF screen simultaneously.

The project must be developed progressively.

At the end of each milestone, provide:

* Files created or modified.
* Implemented functions.
* Tests performed.
* Known limitations.
* Exact run commands.
* Next milestone.

When a technical decision is necessary, prefer the simplest maintainable solution that satisfies this specification.

Do not claim something is complete unless it has been implemented and tested.

Begin implementation immediately after inspecting the environment.

⸻

49. FINAL PRODUCT RULE

MYCROP is not a traditional cropping application.

Its purpose is to eliminate unwanted internal strips while preserving and recombining the remaining content.

The essential experience is:

IMPORT → SELECT → REMOVE → JOIN → REPEAT → EXPORT

Everything else must support this experience.

The application must be visually attractive, technically correct, fast, and easy to use.

The original editing experience, SMASH animation, PDF page handling and automatic continuous-cut workflow must remain consistent with these specifications.

END OF MASTER DEVELOPMENT PROMPT — MYCROP