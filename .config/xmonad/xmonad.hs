--IMPORTS
import XMonad

--Layouts
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Layout.LimitWindows (limitWindows)
import XMonad.Layout.Magnifier hiding (Toggle)
import XMonad.Layout.NoBorders (smartBorders, noBorders)
import XMonad.Layout.Renamed
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.ToggleLayouts

--Utils
import XMonad.Util.EZConfig
import XMonad.Util.Loggers
import XMonad.Util.Ungrab

--Hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

--Actions
import XMonad.Actions.GroupNavigation

myTerminal :: String
myTerminal = "alacritty"

myLayout = toggleLayouts (noBorders Full) (  myTabbed
                                         ||| myTiled
                                         ||| threeC
                                         ||| hacking)
  where
    myTiled = smartBorders $ ResizableTall 1 (5/100) (3/5) []
    myTabbed = noBorders $ tabbed shrinkText def
    threeC
      = renamed [Replace "ThreeCol"]
      $ magnifiercz' 1.3
      $ ThreeColMid nmaster delta ratio
    hacking = renamed [Replace "Hacking"]
      . limitWindows 3
      . magnify 1.3 (NoMaster 3) True
      $ ResizableTall nmaster delta ratio []
    nmaster = 1
    delta = 3/100
    ratio = 1/2

myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          = red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

    -- | Windows should have *some* title, which should not exceed a sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""

myManageHook :: ManageHook
myManageHook = composeAll
    [ className =? "Gimp" --> doFloat
    , isDialog            --> doFloat
    ]

main :: IO ()
main = xmonad
     . ewmhFullscreen
     . ewmh
     . withEasySB (statusBarProp "xmobar ~/.config/xmobar/xmobarrc" (pure myXmobarPP)) defToggleStrutsKey
     $ myConfig

myConfig = def
  { modMask    = mod4Mask
  , layoutHook = spacingRaw True (Border 5 5 5 5) True (Border 5 5 5 5) True $ myLayout
  , manageHook = myManageHook
  , logHook    = historyHook
  , terminal   = myTerminal
  }
  `additionalKeysP`
  [ ("M-]"  , spawn "firefox"            )
  , ("M-S-=", unGrab *> spawn "scrot -s" )
  , ("M-S-l"  , spawn "~/.config/rofi/bin/applet_powermenu")
  , ("M-r"  , spawn "~/.config/rofi/bin/applet_apps")
  , ("M-m" , spawn "pamixer -d 5 && notify-send booty")
  , ("M-f" , sendMessage (Toggle "Full"))
  , ("M-z" , sendMessage MirrorShrink)
  , ("M-a" , sendMessage MirrorExpand)
  , ("M-x" , nextMatch History (return True))
  ]

