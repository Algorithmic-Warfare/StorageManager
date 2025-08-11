# UI Component Styling Workflow

This workflow outlines the steps for styling UI components consistently using CSS variables.

!!! IMPORTANT !!!
- Do not change the existing variables in `App.css`.
- Make the newly defined variables work with the existing theme.

## 1. Planning Phase
- Analyze component structure
- Identify styling elements (colors, typography, spacing, etc.)
- Determine theme requirements
- Example from AlertDialog:
  ```tsx
  // Identified elements:
  // - Overlay background
  // - Content container styles
  // - Title/description text
  ```

## 2. CSS Variables Definition
- Add to App.css under `@theme inline`
- Follow naming convention: `--[component]-[part]-[property]`
- Example:
  ```css
  /* AlertDialog Variables */
  --alert-dialog-overlay-bg: rgba(0, 0, 0, 0.5);
  --alert-dialog-title-color: var(--foreground);
  ```

## 3. Component Implementation
- Replace hardcoded values with variables
- Use `cn()` utility for class merging
- Example:
  ```tsx
  className={cn(
    "bg-[var(--alert-dialog-content-bg)]",
    "border-[var(--alert-dialog-content-border)]"
  )}
  ```

## 4. Validation
- Run build: `pnpm build`
- Check in development environment
- Verify theme consistency

## Full AlertDialog Example

**Before:**
```tsx
const AlertDialogOverlay = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Overlay>,
  React.ComponentProps<typeof AlertDialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <AlertDialogPrimitive.Overlay
    ref={ref}
    data-slot="alert-dialog-overlay"
    className={cn(
      "data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50 bg-black/50",
      className
    )}
    {...props}
  />
));
```

**After:**
```tsx
const AlertDialogOverlay = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Overlay>,
  React.ComponentProps<typeof AlertDialogPrimitive.Overlay>
>(({ className, ...props }, ref) => (
  <AlertDialogPrimitive.Overlay
    ref={ref}
    data-slot="alert-dialog-overlay"
    className={cn(
      "data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 fixed inset-0 z-50",
      "bg-[var(--alert-dialog-overlay-bg)] backdrop-blur-[var(--alert-dialog-overlay-blur)]",
      className
    )}
    {...props}
  />
));

```

## 5. Finalization

Once done formulate a commit message following standards. Show that commit message to the user while prompting him with selection buttons to choose between,
1. Proceeding with the commit.
2. Reformulate the commit.
3. Not commit yet.

Using,
```md
<ask_followup_question>
<question>What would you like to do with this commit message?</question>
<options>
["Proceed with the commit", "Reformulate the commit", "Do not commit yet"]
</options>
</ask_followup_question>

```

If the user chooses (1.) then use command line to make a commit.
```md
<execute_command>
<command>git add . && git commit -m "feat(ui): Add CSS variables for AlertDialog component" -m "This commit introduces CSS variables for styling the AlertDialog component, ensuring consistent theming and easier maintenance.
- Defined --alert-dialog-overlay-bg and --alert-dialog-overlay-blur
- Replaced hardcoded values with new CSS variables in AlertDialogOverlay"</command>
<requires_approval>true</requires_approval>
</execute_command>

```

If the user chooses (2.) then prompt the user for direction about the reformulation.

Using,
```md
<ask_followup_question>
<question>Please provide directions for how you would like to reformulate the commit message.</question>
</ask_followup_question>
```

If the user chooses (3) then stop right there and await further prompting from the user.