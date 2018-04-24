import System.IO
import System.Exit
import XMonad hiding((|||))
import XMonad.Hooks.EwmhDesktops as E
import XMonad.Layout.NoBorders
import XMonad.Layout.Fullscreen
import XMonad.StackSet as W
import Data.Map as M
import XMonad.Actions.CycleWS
import XMonad.Layout.LayoutCombinators --((|||), JumpToLayout)
import XMonad.Layout.WindowNavigation
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Layout.Tabbed
--import XMonad.Util.EZConfig(additionalKeys)
--import XMonad.Util.Run(spawnPipe)

-- main = xmonad $ def
main = xmonad $ fullscreenSupport $ def
        { modMask = mod4Mask -- Use Super instead of Alt
        , terminal = "xfce4-terminal"
        , handleEventHook = E.fullscreenEventHook
        , manageHook = fullscreenManageHook
        , borderWidth = 1
        , normalBorderColor = "#000000"  
        , focusedBorderColor = "#FF0000"
--        , layoutHook = noBorders Full ||| simpleTabbed ||| Tall 1 (3/100) (1/2)||| Mirror (Tall 1 (3/100) (1/2))
        , layoutHook = smartBorders $ renamed [Replace "simpleTabbed"] simpleTabbed ||| Full ||| windowNavigation ( Tall 1 (3/100) (1/2) ) ||| windowNavigation ( Mirror ( Tall 1 (3/100) (1/2)) )
        , XMonad.keys = myKeys
        -- more changes
        }

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
  ----------------------------------------------------------------------
  -- Custom key bindings
  --

  -- Start a terminal.  Terminal to start is specified by myTerminal variable.
  [ --((modMask, xK_Return),
    -- spawn $ XMonad.terminal conf)

  (( 0 , xK_Pause),
     spawn $ XMonad.terminal conf)

  , (( 0 , xK_Scroll_Lock),
     spawn "light-locker-command -l")

  , (( 0 , xK_Print),
     spawn "xfce4-screenshooter")

  , (( 0 , xK_Menu),
     spawn "xfce4-appfinder")

  , ((modMask, xK_Menu),
     spawn "dmenu_run")

  , ((modMask, xK_w),
     spawn "google-chrome-stable")

  , ((modMask, xK_k),
     spawn "google-chrome-stable https://keep.google.com")

  , ((modMask, xK_i),
     spawn "google-chrome-stable https://inbox.google.com")

  , ((modMask, xK_o),
     spawn "google-chrome-stable https://contacts.google.com")

  , ((modMask, xK_c),
     spawn "google-chrome-stable https://calendar.google.com")

--  Change wallpaper
--  , ((modMask .|. controlMask, xK_w),
--     spawn "~/.xmonad/bin/wallpaper")


  -- Close focused window.
  , ((modMask .|. shiftMask, xK_Escape),
     kill)

  -- Cycle through the available layout algorithms.
  , ((modMask, xK_space),
     sendMessage NextLayout)

  --  Reset the layouts on the current workspace to default.
  , ((modMask .|. shiftMask, xK_space),
     setLayout $ XMonad.layoutHook conf)

  , ((modMask, xK_f),
     sendMessage $ JumpToLayout "Full" )

  , ((modMask, xK_t),
     sendMessage $ JumpToLayout "simpleTabbed" )

  -- Resize viewed windows to the correct size.
  , ((modMask, xK_n),
     refresh)

  -- Move focus to the next window.
  , ((controlMask, xK_grave),
     windows W.focusDown)

  -- Move focus to the previous window.
  , ((controlMask .|. shiftMask, xK_grave),
     windows W.focusUp)

  , ((modMask, xK_Left),
--     windows W.focusDown)
     sendMessage $ Go L) 

  , ((modMask, xK_Right),
--     windows W.focusDown)
     sendMessage $ Go R) 

  -- Move focus to the next window.
  , ((modMask, xK_Down),
--     windows W.focusDown)
     sendMessage $ Go D) 

  -- Move focus to the previous window.
  , ((modMask, xK_Up),
--     windows W.focusUp)
     sendMessage $ Go U)

  , ((modMask .|. shiftMask, xK_Page_Up),
     windows W.swapUp)

  , ((modMask .|. shiftMask, xK_Page_Down),
     windows W.swapDown)

  -- Move focus to the master window.
  , ((modMask, xK_m),
     windows W.focusMaster  )

  -- Swap the focused window and the master window.
  , ((modMask, xK_Return),
     windows W.swapMaster)

  -- Swap the focused window with the next window.
  , ((modMask, xK_Page_Down),
     windows W.focusDown)

  -- Swap the focused window with the previous window.
  , ((modMask, xK_Page_Up),
     windows W.focusUp)

  -- Shrink the master area.
  , ((modMask, xK_KP_Subtract),
     sendMessage Shrink)

  -- Expand the master area.
  , ((modMask, xK_KP_Add),
     sendMessage Expand)

  -- Push window back into tiling.
  , ((modMask .|. shiftMask, xK_t),
     withFocused $ windows . W.sink)

  -- Increment the number of windows in the master area.
  , ((modMask, xK_comma),
     sendMessage (IncMasterN 1))

  -- Decrement the number of windows in the master area.
  , ((modMask, xK_period),
     sendMessage (IncMasterN (-1)))

--  , (( modMask .|. controlMask, xK_Page_Up),
--    prevWS )

--  , (( modMask .|. controlMask, xK_Page_Down),
--    nextWS )

--  , (( modMask .|. shiftMask, xK_Page_Up),
--    shiftToPrev >> prevWS )

--  , (( modMask .|. shiftMask, xK_Page_Down),
--    shiftToNext >> nextWS )

  -- Quit xmonad.
  , ((mod1Mask .|. controlMask, xK_Delete),
     io (exitWith ExitSuccess))

  -- Restart xmonad.
  , ((modMask .|. shiftMask, xK_r),
     restart "xmonad" True)
  ]
  ++

  -- mod-[1..9], Switch to workspace N
  -- mod-shift-[1..9], Move client to workspace N
  [((m .|. modMask, k), windows $ f i)
      | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
      , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
--  ++

 -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
 -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
--  [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
--      | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
--      , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- Mouse bindings
--
-- Focus rules
-- True if your focus should follow your mouse cursor.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
  [
    -- mod-button1, Set the window to floating mode and move by dragging
    ((modMask, button1),
     (\w -> XMonad.focus w >> mouseMoveWindow w))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2),
       (\w -> XMonad.focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3),
       (\w -> XMonad.focus w >> mouseResizeWindow w))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]

