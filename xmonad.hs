-- Base
import XMonad
import System.Directory
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W
import qualified Codec.Binary.UTF8.String as UTF8

    -- Actions
import XMonad.Actions.CopyWindow (kill1)
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)
import qualified XMonad.Actions.Search as S

    -- Data
import Data.Char (isSpace, toUpper)
import Data.Maybe (fromJust)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M

    -- Hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat)
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory


    -- Layouts
import XMonad.Layout.Accordion
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.WindowNavigation
import XMonad.Layout.ThreeColumns

    -- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

   -- Utilities
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig (additionalKeysP, additionalMouseBindings)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import qualified DBus as D
import qualified DBus.Client as D

myFont :: String
myFont = "xft:SauceCodePro Nerd Font Mono:regular:size=15:antialias=true:hinting=true"

myModMask :: KeyMask
myModMask = mod4Mask        -- Sets modkey to super/windows key

myTerminal :: String
myTerminal = "alacritty"    -- Sets default terminal

myBrowser :: String
myBrowser = "brave"  -- Sets brave as browser

myEmacs :: String
myEmacs = "emacsclient -c -a 'emacs' "  -- Sets emacs as editor

myEditor :: String
myEditor = "emacsclient -c -a 'emacs' "  -- Sets emacs as editor
-- myEditor = myTerminal ++ " -e vim "    -- Sets vim as editor

myNote :: String;           -- Sets Handwritten Notetaking app
myNote = "xournalpp";

myEmail :: String;           -- Sets default email client
myEmail = "mailspring";

myBorderWidth :: Dimension
myBorderWidth = 2           -- Sets border width for windows

myNormColor :: String
myNormColor   = "#282c34"   -- Border color of normal windows

myFocusColor :: String
myFocusColor  = "#46d9ff"   -- Border color of focused windows

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

mySearch :: String;
mySearch = "rofi -show run -m -4"

myOffice :: String;
myOffice = "libreoffice";

myPass :: String;
myPass = "bitwarden-desktop";

myRecorder :: String;
myRecorder = "obs";

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myStartupHook :: X ()
myStartupHook = do
    spawn "~/.scripts/system/autostart.sh"

myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
                , NS "passwordManager" spawnPass findPass managePass
                , NS "deadbeef" spawnDeadbeef findDeadbeef manageDeadbeef
                , NS "discord" spawnDiscord findDiscord manageDiscord
                , NS "firefox" spawnBrowser findBrowser manageBrowser
                , NS "calculator" spawnCalc findCalc manageCalc
                ]
  where
    spawnTerm           = myTerminal ++ " -t scratchpad"
    findTerm            = title =? "scratchpad"
    manageTerm          = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.9
                 w      = 0.9
                 t      = 0.95 -h
                 l      = 0.95 -w
    spawnDiscord        = "discord"
    findDiscord         = className =? "discord"
    manageDiscord       = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.9
                 w      = 0.9
                 t      = 0.95 -h
                 l      = 0.95 -w
    spawnPass           = myPass
    findPass            = className =? "Bitwarden"
    managePass          = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.9
                 w      = 0.4
                 t      = 0.95 -h
                 l      = 0.98 -w
    spawnBrowser        = "firefox"
    findBrowser         = className =? "firefox"
    manageBrowser       = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.9
                 w      = 0.9
                 t      = 0.95 -h
                 l      = 0.95 -w
    spawnDeadbeef       = "deadbeef"
    findDeadbeef        = className =? "Deadbeef"
    manageDeadbeef      = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.9
                 w      = 0.9
                 t      = 0.95 -h
                 l      = 0.95 -w
    spawnCalc           = "qalculate-gtk"
    findCalc            = className =? "Qalculate-gtk"
    manageCalc          = customFloating $ W.RationalRect l t w h
               where
                 h      = 0.5
                 w      = 0.4
                 t      = 0.75 -h
                 l      = 0.70 -w

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Below is a variation of the above except no borders are applied
-- if fewer than two windows. So a single window has no gaps.
mySpacing' :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True

-- Defining a bunch of layouts, many that I don't use.
-- limitWindows n sets maximum number of windows displayed for layout.
-- mySpacing n sets the gap size around the windows.
tall     = renamed [Replace "tall"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ limitWindows 12
           $ ResizableTall 1 (3/100) (1/2) []
floats   = renamed [Replace "floats"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ limitWindows 20 simplestFloat
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabTheme

-- setting colors for tabs layout and tabs sublayout.
myTabTheme = def { fontName            = myFont
                 , activeColor         = "#ff2afc"
                 , inactiveColor       = "#1f1147"
                 , activeBorderColor   = "#ff2afc"
                 , inactiveBorderColor = "#1f1147"
                 , activeTextColor     = "#1f1147"
                 , inactiveTextColor   = "#ff2afc"
                 }

-- Theme for showWName which prints current workspace when you change workspaces.
myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = "xft:Ubuntu:bold:size=60"
    , swn_fade              = 0.5
    , swn_bgcolor           = "#1c1f24"
    , swn_color             = "#ffffff"
    }

-- The layout hook
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =
                                        tall
                                        ||| noBorders tabs

myLogHook :: D.Client -> PP
myLogHook dbus = def { ppOutput = dbusOutput dbus
                       }
dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
            D.signalBody = [D.toVariant $ UTF8.decodeString str]
        }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"

-- myWorkspaces = [" 1 ", " 2 ", " 3 ", " 4 ", " 5 ", " 6 ", " 7 ", " 8 ", " 9 "]
myWorkspaces = ["dev", "sys", "note", "www", "doc", "mail", "chat", "media", "misc", "NSP"]
-- clickable ws = "<action=xdotool key super+"++show i++">"++ws++"</action>"
--     where i = fromJust $ M.lookup ws myWorkspaceIndices #+END_SRC

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     -- 'doFloat' forces a window to float.  Useful for dialog boxes and such.
     -- using 'doShift ( myWorkspaces !! 7)' sends program to workspace 8!
     -- I'm doing it this way because otherwise I would have to write out the full
     -- name of my workspaces and the names would be very long if using clickable workspaces.
     [ className =? "confirm"                   --> doFloat
     , className =? "file_progress"             --> doFloat
     , className =? "dialog"                    --> doFloat
     , className =? "download"                  --> doFloat
     , className =? "error"                     --> doFloat
     , className =? "Gimp"                      --> doFloat
     , className =? "notification"              --> doFloat
     , className =? "pinentry-gtk-2"            --> doFloat
     , className =? "splash"                    --> doFloat
     , className =? "toolbar"                   --> doFloat
     , title =? "Oracle VM VirtualBox Manager"  --> doFloat
     , title =? "Messenger Call - Brave"        --> doShift ( myWorkspaces !! 6 )
     , className =? "zoom"                      --> doShift ( myWorkspaces !! 6 )
     , className =? "qutebrowser"               --> doShift ( myWorkspaces !! 3 )
     , className =? "Brave-browser"             --> doShift ( myWorkspaces !! 3 )
     , className =? "Mail"                      --> doShift ( myWorkspaces !! 5 )
     , className =? "Thunderbird"               --> doShift ( myWorkspaces !! 5 )
     , className =? "Mailspring"                --> doShift ( myWorkspaces !! 5 )
     , className =? "Gcr-prompter"              --> doShift ( myWorkspaces !! 5 ) -- mailspring's gnome keyring's password prompt
     , className =? "mpv"                       --> doShift ( myWorkspaces !! 7 )
     , className =? "Gimp"                      --> doShift ( myWorkspaces !! 2 )
     , className =? "Write"                     --> doShift ( myWorkspaces !! 2 )
     , className =? "Xournalpp"                     --> doShift ( myWorkspaces !! 2 )
     , className =? "VirtualBox Manager" --> doShift  ( myWorkspaces !! 9 )
     , (className =? "firefox" <&&> resource =? "Dialog") --> doFloat  -- Float Firefox Dialog
     , isFullscreen -->  doFullFloat
     ] <+> namedScratchpadManageHook myScratchPads

myMouseBindings =

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((mod4Mask, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((mod4Mask, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((mod4Mask, button3), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster))

    --wacom
    , ((0, 16), (\w -> spawn "wacom-main"))
    , ((0, 15), (\w -> spawn "wacom-side"))

    ]

myWorkspaceKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $

  [((m .|. modMask, k), windows $ f i)

  --Keyboard layouts
  --qwerty users use this line
   | (i, k) <- zip (XMonad.workspaces conf) [xK_1,xK_2,xK_3,xK_4,xK_5,xK_6,xK_7,xK_8,xK_9,xK_0,xK_F13]

  --French Azerty users use this line
  -- | (i, k) <- zip (XMonad.workspaces conf) [xK_ampersand, xK_eacute, xK_quotedbl, xK_apostrophe, xK_parenleft, xK_minus, xK_egrave, xK_underscore, xK_ccedilla , xK_agrave]

  --Belgian Azerty users use this line
  -- | (i, k) <- zip (XMonad.workspaces conf) [xK_ampersand, xK_eacute, xK_quotedbl, xK_apostrophe, xK_parenleft, xK_section, xK_egrave, xK_exclam, xK_ccedilla, xK_agrave]

      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)
      , (\i -> W.greedyView i . W.shift i, shiftMask)]]

   ++
  -- ctrl-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
  -- ctrl-shift-{w,e,r}, Move client to screen 1, 2, or 3
  [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
      | (key, sc) <- zip [xK_w, xK_e] [0..]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

myKeys :: [(String, X ())]
myKeys =
    -- Xmonad
        [
          ("M1-r", spawn "xmonad --recompile")  -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")    -- Restarts xmonad
        , ("M1-<F4>", spawn "arcolinux-logout")    -- Restarts xmonad

-- Run Prompt
    , ("M-S-<Return>", spawn mySearch) -- rofi
    , ("M-p p", spawn "~/.scripts/rofi/display")   -- display changing scripts
    , ("M-p a", spawn "~/.scripts/rofi/soundcard-choose")   -- choose default sink/source for audio
    , ("M-p e", spawn "rofi -show emoji")  -- insert emoji
    , ("M-p m", spawn "~/.scripts/rofi/rofi-music/music.sh")   -- choose music using mpd with mpc
    , ("M-p b", spawn "~/.scripts/rofi/bluetooth")   -- using bluetoothcli scripts
    , ("M-p w", spawn "~/.scripts/rofi/wifi")   --  connect network through nmcli scripts
    , ("M-p t", spawn "~/.scripts/rofi/wacom")   --  configure drawing tablet

-- Run Prompt
    , ("M-o y", spawn "~/.scripts/rofi/rofi-youtube/rofi-youtube")   --  search youtube
    , ("M-o o", spawn "~/.scripts/rofi/rofi-search/search search")   --  search the web using rofi
    , ("M-o m", spawn "~/.scripts/rofi//rofi-search/search quickmark")   --  add quickmark to rofi

-- Useful programs to have a keybinding for launch
    , ("M-<Return>", spawn myTerminal)
    , ("C-M1-w", spawn myBrowser)
    , ("C-M1-e", spawn myEditor)
    , ("C-M1-r", spawn myRecorder)
    , ("C-M1-n", spawn myNote)
    , ("C-M1-m", spawn myEmail)
    , ("C-M1-o", spawn myOffice)

-- Useful programs to have a keybinding for launch
    , ("C-<F11>", spawn "wacom-main")
    , ("C-<F12>", spawn "wacom-side")

--Toggle Polybar
	    , ("M-y", spawn $ "polybar-msg cmd toggle")

-- Kill windows
	    , ("M-S-q", kill1)     -- Kill the currently focused client

-- Workspaces
	    , ("M-.", nextScreen)  -- Switch focus to next monitor
	    , ("M-,", prevScreen)  -- Switch focus to prev monitor
	    , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next ws
	    , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to prev ws

-- Floating windows
	    , ("M-t", withFocused $ windows . W.sink)  -- Push floating window back to tile
	    , ("M-S-t", sinkAll)                       -- Push ALL floating windows to tile

-- Increase/decrease spacing (gaps)
	    , ("C-M1-j", decWindowSpacing 4)         -- Decrease window spacing
	    , ("C-M1-k", incWindowSpacing 4)         -- Increase window spacing
	    , ("C-M1-h", decScreenSpacing 4)         -- Decrease screen spacing
	    , ("C-M1-l", incScreenSpacing 4)         -- Increase screen spacing

-- Windows navigation
	    , ("M-m", windows W.focusMaster)  -- Move focus to the master window
	    , ("M-j", windows W.focusDown)    -- Move focus to the next window
	    , ("M-k", windows W.focusUp)      -- Move focus to the prev window
	    , ("M-S-m", windows W.swapMaster) -- Swap the focused window and the master window
	    , ("M-S-j", windows W.swapDown)   -- Swap focused window with next window
	    , ("M-S-k", windows W.swapUp)     -- Swap focused window with prev window
	    , ("M-<Backspace>", promote)      -- Moves focused window to master, others maintain order
	    , ("M-S-<Tab>", rotSlavesDown)    -- Rotate all windows except master and keep focus in place
	    , ("M-C-<Tab>", rotAllDown)       -- Rotate all the windows in the current stack

-- Layouts
	    , ("M-<Tab>", sendMessage NextLayout)           -- Switch to next layout
	    , ("M-<space>", sendMessage NextLayout)           -- Switch to next layout
	    , ("M-f", sendMessage (MT.Toggle NBFULL) >> sendMessage ToggleStruts) -- Toggles noborder/full

-- Increase/decrease windows in the master pane or the stack
	    , ("M-S-<Up>", sendMessage (IncMasterN 1))      -- Increase # of clients master pane
	    , ("M-S-<Down>", sendMessage (IncMasterN (-1))) -- Decrease # of clients master pane
	    , ("M-C-<Up>", increaseLimit)                   -- Increase # of windows
	    , ("M-C-<Down>", decreaseLimit)                 -- Decrease # of windows

-- Window resizing
	    , ("M-M1-h", sendMessage Shrink)                   -- Shrink horiz window width
	    , ("M-M1-l", sendMessage Expand)                   -- Expand horiz window width
	    , ("M-M1-j", sendMessage MirrorShrink)          -- Shrink vert window width
	    , ("M-M1-k", sendMessage MirrorExpand)          -- Expand vert window width

-- Sublayouts
-- This is used to push windows to tabbed sublayouts, or pull them out of it.
	    , ("M-C-h", sendMessage $ pullGroup L)
	    , ("M-C-l", sendMessage $ pullGroup R)
	    , ("M-C-k", sendMessage $ pullGroup U)
	    , ("M-C-j", sendMessage $ pullGroup D)
	    , ("M-C-m", withFocused (sendMessage . MergeAll))
-- , ("M-C-u", withFocused (sendMessage . UnMerge))
	    , ("M-C-/", withFocused (sendMessage . UnMergeAll))
	    , ("M-C-.", onGroup W.focusUp')    -- Switch focus to next tab
	    , ("M-C-,", onGroup W.focusDown')  -- Switch focus to prev tab

-- Scratchpads
-- Toggle show/hide these programs.  They run on a hidden workspace.
-- When you toggle them to show, it brings them to your current workspace.
-- Toggle them to hide and it sends them back to hidden workspace (NSP).
    , ("C-s t", namedScratchpadAction myScratchPads "terminal")
    , ("C-s d", namedScratchpadAction myScratchPads "discord")
    , ("C-s p", namedScratchpadAction myScratchPads "passwordManager")
    , ("C-s b", namedScratchpadAction myScratchPads "firefox")
    , ("C-s m", namedScratchpadAction myScratchPads "deadbeef")
    , ("C-s c", namedScratchpadAction myScratchPads "calculator")

-- Controls for deadbeef music player (SUPER-u followed by a key)
    , ("M-u p", spawn "deadbeef --play-pause")
    , ("M-u l", spawn "deadbeef --next")
    , ("M-u h", spawn "deadbeef --prev")

-- Emacs (CTRL-e followed by a key)
    , ("C-e e", spawn "emacsclient --eval '(emacs-everywhere)'")    -- emacs everywhere
    , ("C-e b", spawn (myEmacs ++ ("--eval '(ibuffer)'")))          -- list buffers
    , ("C-e d", spawn (myEmacs ++ ("--eval '(dired nil)'")))        -- dired
    , ("C-e s", spawn (myEmacs ++ ("--eval '(eshell)'")))           -- eshell

-- Multimedia Keys
   , ("<XF86AudioPlay>", spawn "playerctl play-pause")
    , ("M-S-/", spawn "playerctl play-pause")
    , ("<XF86AudioPrev>", spawn "playerctl previous")
    , ("M-S-,", spawn "playerctl previous")
    , ("<XF86AudioNext>", spawn "playerctl next")
    , ("M-S-.", spawn "playerctl next")
    , ("<XF86AudioMute>", spawn "~/.scripts/system/pavolume.sh --togmute")
    , ("<XF86AudioLowerVolume>", spawn "~/.scripts/system/pavolume.sh --down")
    , ("<XF86AudioRaiseVolume>", spawn "~/.scripts/system/pavolume.sh --up")
    , ("<XF86MonBrightnessUp>", spawn "lux -a 3%")
    , ("<XF86MonBrightnessDown>", spawn "lux -s 3%")
    , ("<XF86TouchpadToggle>", spawn "$HOME/.scripts/system/touchpad-toggle")
    , ("<Print>", spawn "~/.scripts/system/print-screen -c")
    , ("C-<Print>", spawn "~/.scripts/system/print-screen -w")
    , ("C-S-<Print>", spawn "~/.scripts/system/print-screen -a")
    ]
-- The following lines are needed for named scratchpads.
      where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
            nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))

main :: IO ()
main = do
    dbus <- D.connectSession
    -- Request access to the DBus name
    _ <- D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
    -- the xmonad, ya know...what the WM is named after!
    xmonad $ ewmh def
        { manageHook            = myManageHook <+> manageDocks
        , handleEventHook       = docksEventHook
                               -- Uncomment this line to enable works perfect on SINGLE monitor systems. On multi-monitor systems,
                               -- it adds a border around the window if screen does not have focus. So, my solution
                               -- is to use a keybinding to toggle fullscreen noborders instead.  (M-<Space>)
                               -- <+> fullscreenEventHook
        , modMask               = myModMask
        , terminal              = myTerminal
        , startupHook           = myStartupHook
        , layoutHook            = showWName' myShowWNameTheme $ myLayoutHook
        , logHook               = dynamicLogWithPP (myLogHook dbus)
        , focusFollowsMouse     = myFocusFollowsMouse
        , workspaces            = myWorkspaces
        , keys                  = myWorkspaceKeys
        , borderWidth           = myBorderWidth
        , normalBorderColor     = myNormColor
        , focusedBorderColor    = myFocusColor
        } `additionalKeysP` myKeys
        `additionalMouseBindings` myMouseBindings
