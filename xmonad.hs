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
myBrowser = "qutebrowser"  -- Sets qutebrowser as browser

myEmacs :: String
myEmacs = "emacsclient -c -a 'emacs' "  -- Sets emacs as editor

myEditor :: String
myEditor = "emacsclient -c -a 'emacs' "  -- Sets emacs as editor
-- myEditor = myTerminal ++ " -e vim "    -- Sets vim as editor

myNote :: String;           -- Sets Handwritten Notetaking app
myNote = "Write_app";

myEmail :: String;           -- Sets Handwritten Notetaking app
myEmail = "thunderbird";

myBorderWidth :: Dimension
myBorderWidth = 2           -- Sets border width for windows

myNormColor :: String
myNormColor   = "#282c34"   -- Border color of normal windows

myFocusColor :: String
myFocusColor  = "#46d9ff"   -- Border color of focused windows

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

mySearch :: String;
mySearch = "dmenu_run -i -nb '#191919' -nf '#fea63c' -sb '#fea63c' -sf '#191919' -fn 'NotoMonoRegular:bold:pixelsize=15'"

myOffice :: String;
myOffice = "libreoffice";

myPass :: String;
myPass = "bitwarden";

windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

myStartupHook :: X ()
myStartupHook = do
    spawn "~/.xmonad/scripts/autostart.sh"

myScratchPads :: [NamedScratchpad]
myScratchPads = [ NS "terminal" spawnTerm findTerm manageTerm
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
           -- $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
magnify  = renamed [Replace "magnify"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           $ magnifier
           $ limitWindows 12
           $ mySpacing 8
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           $ limitWindows 20 Full
floats   = renamed [Replace "floats"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           $ limitWindows 20 simplestFloat
grid     = renamed [Replace "grid"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 0
           $ mkToggle (single MIRROR)
           $ Grid (16/10)
-- spirals  = renamed [Replace "spirals"]
           -- $ windowNavigation
           -- $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           -- $ mySpacing' 8
           -- $ spiral (6/7)
threeCol = renamed [Replace "threeCol"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           $ limitWindows 7
           $ ThreeCol 1 (3/100) (1/2)
-- threeRow = renamed [Replace "threeRow"]
           -- $ windowNavigation
           -- $ addTabs shrinkText myTabTheme
           -- $ subLayout [] (smartBorders Simplest)
           -- $ limitWindows 7
           -- Mirror takes a layout and rotates it by 90 degrees.
           -- So we are applying Mirror to the ThreeCol layout.
           -- $ Mirror
           -- $ ThreeCol 1 (3/100) (1/2)
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabTheme

-- setting colors for tabs layout and tabs sublayout.
myTabTheme = def { fontName            = myFont
                 , activeColor         = "#46d9ff"
                 , inactiveColor       = "#313846"
                 , activeBorderColor   = "#46d9ff"
                 , inactiveBorderColor = "#282c34"
                 , activeTextColor     = "#282c34"
                 , inactiveTextColor   = "#d0d0d0"
                 }

-- Theme for showWName which prints current workspace when you change workspaces.
myShowWNameTheme :: SWNConfig
myShowWNameTheme = def
    { swn_font              = "xft:Ubuntu:bold:size=60"
    , swn_fade              = 1.0
    , swn_bgcolor           = "#1c1f24"
    , swn_color             = "#ffffff"
    }

-- The layout hook
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts floats
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     tall
                                 ||| magnify
                                 ||| noBorders monocle
                                 ||| floats
                                 ||| noBorders tabs
                                 ||| grid
                                 -- ||| spirals
                                 ||| threeCol
                                 -- ||| threeRow

myLogHook :: D.Client -> PP
myLogHook dbus = def { ppOutput = dbusOutput dbus }
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
myWorkspaces = [" dev ", " sys ", " note ", "www ", " doc ", " mail ", " chat ", " media ", " misc "]
myWorkspaceIndices = M.fromList $ zipWith (,) myWorkspaces [1..] -- (,) == \x y -> (x,y)

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
     -- , title =? "Mozilla Firefox"               --> doShift ( myWorkspaces !! 3 )
     , className =? "brave-browser"             --> doShift ( myWorkspaces !! 3 )
     -- , className =? "discord"                   --> doShift ( myWorkspaces !! 6 )
     , className =? "zoom"                      --> doShift ( myWorkspaces !! 8 )
     , className =? "qutebrowser"               --> doShift ( myWorkspaces !! 3 )
     , className =? "Mail"                      --> doShift ( myWorkspaces !! 5 )
     , className =? "Thunderbird"               --> doShift ( myWorkspaces !! 5 )
     , className =? "mpv"                       --> doShift ( myWorkspaces !! 7 )
     , className =? "Gimp"                      --> doShift ( myWorkspaces !! 2 )
     , className =? "Write"                     --> doShift ( myWorkspaces !! 2 )
     -- , className =? "VirtualBox Manager" --> doShift  ( myWorkspaces !! 4 )
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
    , ((0, 16), (\w -> spawn "wacom_main"))
    , ((0, 15), (\w -> spawn "wacom_side"))

    ]

myKeys :: [(String, X ())]
myKeys =
    -- Xmonad
        [ ("M1-r", spawn "xmonad --recompile")  -- Recompiles xmonad
        , ("M-S-r", spawn "xmonad --restart")    -- Restarts xmonad

    -- Run Prompt
        , ("M-S-<Return>", spawn mySearch) -- Dmenu

        -- , ("M-p c", spawn "~/dmscripts/dcolors")  -- pick color from our scheme
        -- , ("M-p e", spawn "~/dmscripts/dmconf")   -- edit config files
        -- , ("M-p k", spawn "~/dmscripts/dmkill")   -- kill processes
        -- , ("M-p m", spawn "~/dmscripts/dman")     -- manpages
        -- , ("M-p o", spawn "~/dmscripts/dmqute")   -- qutebrowser bookmarks/history
        -- , ("M-p p", spawn "passmenu")                    -- passmenu
        -- , ("M-p q", spawn "~/dmscripts/dmlogout") -- logout menu
        -- , ("M-p r", spawn "~/dmscripts/dmred")    -- reddio (a reddit viewer)
        -- , ("M-p s", spawn "~/dmscripts/dmsearch") -- search various search engines

    -- Useful programs to have a keybinding for launch
        , ("M-<Return>", spawn (myTerminal))
        , ("C-M1-w", spawn myBrowser)
        , ("C-M1-e", spawn myEditor)
        , ("C-M1-n", spawn myNote)
        , ("C-M1-m", spawn myEmail)
        , ("C-M1-o", spawn myOffice)
        , ("C-M1-p", spawn myPass)

    -- Useful programs to have a keybinding for launch
        , ("C-<F11>", spawn "wacom_main")
        , ("C-<F12>", spawn "wacom_side")

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
        , ("M-h", sendMessage Shrink)                   -- Shrink horiz window width
        , ("M-l", sendMessage Expand)                   -- Expand horiz window width
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
        , ("C-s b", namedScratchpadAction myScratchPads "firefox")
        , ("C-s m", namedScratchpadAction myScratchPads "deadbeef")
        , ("C-s c", namedScratchpadAction myScratchPads "calculator")

    -- Controls for deadbeef music player (SUPER-u followed by a key)
        , ("M-u p", spawn "deadbeef --play-pause")
        , ("M-u l", spawn "deadbeef --next")
        , ("M-u h", spawn "deadbeef --prev")

    -- Emacs (CTRL-e followed by a key)
        -- , ("C-e e", spawn myEmacs)                 -- start emacs
        , ("C-e e", spawn (myEmacs ++ ("--eval '(dashboard-refresh-buffer)'")))   -- emacs dashboard
        , ("C-e b", spawn (myEmacs ++ ("--eval '(ibuffer)'")))   -- list buffers
        , ("C-e d", spawn (myEmacs ++ ("--eval '(dired nil)'"))) -- dired
        -- , ("C-e i", spawn (myEmacs ++ ("--eval '(erc)'")))       -- erc irc client
        -- , ("C-e m", spawn (myEmacs ++ ("--eval '(mu4e)'")))      -- mu4e email
        -- , ("C-e n", spawn (myEmacs ++ ("--eval '(elfeed)'")))    -- elfeed rss
        , ("C-e s", spawn (myEmacs ++ ("--eval '(eshell)'")))    -- eshell
        -- , ("C-e t", spawn (myEmacs ++ ("--eval '(mastodon)'")))  -- mastodon.el
        -- , ("C-e v", spawn (myEmacs ++ ("--eval '(vterm nil)'"))) -- vterm if on GNU Emacs
        , ("C-e v", spawn (myEmacs ++ ("--eval '(+vterm/here nil)'"))) -- vterm if on Doom Emacs
        -- , ("C-e w", spawn (myEmacs ++ ("--eval '(eww \"distrotube.com\")'"))) -- eww browser if on GNU Emacs
        , ("C-e w", spawn (myEmacs ++ ("--eval '(doom/window-maximize-buffer(eww \"distrotube.com\"))'"))) -- eww browser if on Doom Emacs
        -- emms is an emacs audio player. I set it to auto start playing in a specific directory.
        , ("C-e a", spawn (myEmacs ++ ("--eval '(emms)' --eval '(emms-play-directory-tree \"~/Music/Non-Classical/70s-80s/\")'")))

    -- Multimedia Keys
        , ("<XF86AudioPlay>", spawn "deadbeef --play-pause")
        , ("<XF86AudioPrev>", spawn "deadbeef --prev")
        , ("<XF86AudioNext>", spawn "deadbeef --next")
        , ("<XF86AudioMute>", spawn "amixer set Master toggle")
        , ("<XF86AudioLowerVolume>", spawn "amixer set Master 1%- unmute")
        , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 1%+ unmute")
        , ("<XF86MonBrightnessUp>", spawn "lux -a 1000")
        , ("<XF86MonBrightnessDown>", spawn "lux -s 1000")
        , ("<XF86TouchpadToggle>", spawn "touchpad_toggle")
        , ("<Print>", spawn "flameshot gui")
        , ("C-<Print>", spawn "flameshot screen")
        , ("C-S-<Print>", spawn "flameshot full")
        ]
    -- The following lines are needed for named scratchpads.
          where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))

main :: IO ()
main = do
    -- the xmonad, ya know...what the WM is named after!
    dbus <- D.connectSession
    -- Request access to the DBus name
    _ <- D.requestName dbus (D.busName_ "org.xmonad.Log")
        [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
    xmonad $ ewmh def
        { manageHook         = myManageHook <+> manageDocks
        , handleEventHook    = docksEventHook
                               -- Uncomment this line to enable fullscreen support on things like YouTube/Netflix.
                               -- This works perfect on SINGLE monitor systems. On multi-monitor systems,
                               -- it adds a border around the window if screen does not have focus. So, my solution
                               -- is to use a keybinding to toggle fullscreen noborders instead.  (M-<Space>)
                               -- <+> fullscreenEventHook
        , modMask            = myModMask
        , terminal           = myTerminal
        , startupHook        = myStartupHook
        , logHook = dynamicLogWithPP $ namedScratchpadFilterOutWorkspacePP $ xmobarPP
              -- the following variables beginning with 'pp' are settings for xmobar.
              {
                ppOutput = dbusOutput dbus
              , ppExtras  = [windowCount]                                     -- # of windows current workspace
              , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]                    -- order of things in xmobar
              }
        , layoutHook         = showWName' myShowWNameTheme $ myLayoutHook
        , focusFollowsMouse  = myFocusFollowsMouse
        , workspaces         = myWorkspaces
        , borderWidth        = myBorderWidth
        , normalBorderColor  = myNormColor
        , focusedBorderColor = myFocusColor
        } `additionalKeysP` myKeys
        `additionalMouseBindings` myMouseBindings
