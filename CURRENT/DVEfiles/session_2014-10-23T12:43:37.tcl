# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Thu Oct 23 12:43:37 2014
# Designs open: 1
#   Sim: /afs/ece.cmu.edu/usr/jaewonch/Private/class/18-341/p3/jared/simv
# Toplevel windows open: 1
# 	TopLevel.1
#   Source.1: top.host
#   Group count = 3
#   Group rwfsm signal count = 22
#   Group pfsm signal count = 46
#   Group bs signal count = 25
# End_DVE_Session_Save_Info

# DVE version: F-2011.12-SP1
# DVE build date: May 27 2012 20:57:07


#<Session mode="Full" path="/afs/ece.cmu.edu/usr/jaewonch/Private/class/18-341/p3/jared/DVEfiles/session.tcl" type="Debug">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Helvetica,10,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE Topleve session: 


# Create and position top-level windows :TopLevel.1

if {![gui_exist_window -window TopLevel.1]} {
    set TopLevel.1 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.1 TopLevel.1
}
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{214 171} {1641 1014}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_set_toolbar_attributes -toolbar {&File} -dock_state top
gui_set_toolbar_attributes -toolbar {&File} -offset 0
gui_show_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_set_toolbar_attributes -toolbar {BackTrace} -dock_state top
gui_set_toolbar_attributes -toolbar {BackTrace} -offset 0
gui_show_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}

# End ToolBar settings

# Docked window settings
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 283]
set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier]
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 283
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 282} {height 567} {dock_state left} {dock_on_new_line true} {child_hier_colhier 204} {child_hier_coltype 107} {child_hier_col1 0} {child_hier_col2 1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 218]
set Data.1 [gui_share_window -id ${DLPane.1} -type Data]
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 218
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 567
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 217} {height 567} {dock_state left} {dock_on_new_line true} {child_data_colvariable 140} {child_data_colvalue 100} {child_data_coltype 40} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 178]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 1428
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 178
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 1427} {height 177} {dock_state bottom} {dock_on_new_line true}}
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size
gui_sync_global -id ${TopLevel.1} -option true

# MDI window settings
set Source.1 [gui_create_window -type {Source}  -parent ${TopLevel.1}]
gui_show_window -window ${Source.1} -show_state maximized
gui_update_layout -id ${Source.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false}}

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(Source) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Schematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(PathSchematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Wave) none
gui_set_env TOPLEVELS::TARGET_FRAME(List) none
gui_set_env TOPLEVELS::TARGET_FRAME(Memory) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(DriverLoad) none
gui_update_statusbar_target_frame ${TopLevel.1}

#</WindowLayout>

#<Database>

# DVE Open design session: 

if { [llength [lindex [gui_get_db -design Sim] 0]] == 0 } {
gui_set_env SIMSETUP::SIMARGS {{}}
gui_set_env SIMSETUP::SIMEXE {./simv}
gui_set_env SIMSETUP::ALLOW_POLL {0}
if { ![gui_is_db_opened -db {/afs/ece.cmu.edu/usr/jaewonch/Private/class/18-341/p3/jared/simv}] } {
gui_sim_run Ucli -exe simv -args { -ucligui} -dir /afs/ece.cmu.edu/usr/jaewonch/Private/class/18-341/p3/jared -nosource
}
}
if { ![gui_sim_state -check active] } {error "Simulator did not start correctly" error}
gui_set_precision 1s
gui_set_time_units 1s
#</Database>

# DVE Global setting session: 


# Global: Breakpoints

# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups

set rwfsm rwfsm
gui_sg_create ${rwfsm}
gui_sg_addsignal -group ${rwfsm} { top.host.rwfsm.protocol_free top.host.rwfsm.RWmemPage_tmp top.host.rwfsm.read_success top.host.rwfsm.ns top.host.rwfsm.msg_type top.host.rwfsm.ld_w_data top.host.rwfsm.rwFSM_done top.host.rwfsm.ld_mempage top.host.rwfsm.RW_data_write top.host.rwfsm.RWmemPage top.host.rwfsm.rw_dout top.host.rwfsm.start_read top.host.rwfsm.rw_din top.host.rwfsm.clk top.host.rwfsm.rst_L top.host.rwfsm.cs top.host.rwfsm.timeout top.host.rwfsm.write_success top.host.rwfsm.start_write top.host.rwfsm.clr top.host.rwfsm.RW_data_read top.host.rwfsm.data_write_tmp }
set pfsm pfsm
gui_sg_create ${pfsm}
gui_sg_addsignal -group ${pfsm} { top.host.pfsm.got_sync top.host.pfsm.protocol_free top.host.pfsm.CRC_error top.host.pfsm.all_at_wait top.host.pfsm.protocol_dout top.host.pfsm.ns top.host.pfsm.incr_attempt top.host.pfsm.rc_PIDerror top.host.pfsm.pkt_sent top.host.pfsm.abort top.host.pfsm.receive_data top.host.pfsm.device_hshake top.host.pfsm.data top.host.pfsm.data_in_tmp top.host.pfsm.pkt_status top.host.pfsm.msg_type top.host.pfsm.clr_dataWrite top.host.pfsm.incr_count top.host.pfsm.device_data_tmp top.host.pfsm.ld_dataWrite top.host.pfsm.clr_attempt top.host.pfsm.rc_nrzi_wait top.host.pfsm.device_data top.host.pfsm.free_inbound top.host.pfsm.PID_error top.host.pfsm.protocol_din top.host.pfsm.rc_crc_wait top.host.pfsm.clk top.host.pfsm.rst_L top.host.pfsm.cs top.host.pfsm.attempt top.host.pfsm.pkt_error top.host.pfsm.timeout top.host.pfsm.clr_count top.host.pfsm.bs_decoder_wait top.host.pfsm.rc_EOPerror top.host.pfsm.count top.host.pfsm.hshake top.host.pfsm.token top.host.pfsm.pkt_type top.host.pfsm.pkt_rec top.host.pfsm.receive_hshake top.host.pfsm.rc_dpdm_wait top.host.pfsm.rc_CRCerror top.host.pfsm.EOP_error top.host.pfsm.bitUnstuff_wait }
set bs bs
gui_sg_create ${bs}
gui_sg_addsignal -group ${bs} { top.host.bs.ld_d top.host.bs.ld_h top.host.bs.endr top.host.bs.t_shft top.host.bs.pkt_sent top.host.bs.h_shft top.host.bs.h_out top.host.bs.ld_t top.host.bs.t_out top.host.bs.data top.host.bs.s_out top.host.bs.d_out top.host.bs.d_shft top.host.bs.free_inbound top.host.bs.sent_pkt top.host.bs.clk top.host.bs.sel top.host.bs.rst_n top.host.bs.pkt_in top.host.bs.count top.host.bs.hshake top.host.bs.clr top.host.bs.token top.host.bs.pkt_type top.host.bs.incr }

# Global: Highlighting

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 8



# Save global setting...

# Wave/List view global setting
gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 


# Hier 'Hier.1'
gui_show_window -window ${Hier.1}
gui_list_set_filter -id ${Hier.1} -list { {Package 1} {All 0} {Process 1} {UnnamedProcess 1} {Function 1} {Block 1} {OVA Unit 1} {LeafScCell 1} {LeafVlgCell 1} {Interface 1} {PowSwitch 0} {LeafVhdCell 1} {$unit 1} {NamedBlock 1} {Task 1} {VlgPackage 1} {IsoCell 0} {ClassDef 1} }
gui_list_set_filter -id ${Hier.1} -text {*}
gui_hier_list_init -id ${Hier.1}
gui_change_design -id ${Hier.1} -design Sim
catch {gui_list_expand -id ${Hier.1} top}
catch {gui_list_expand -id ${Hier.1} top.host}
catch {gui_list_select -id ${Hier.1} {top.host.rwfsm}}
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {Parameter 1} {All 1} {Aggregate 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {top.host.rwfsm}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active top.host /afs/ece.cmu.edu/usr/jaewonch/Private/class/18-341/p3/jared/usbHost.sv
gui_view_scroll -id ${Source.1} -vertical -set 70
gui_src_set_reusable -id ${Source.1}
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${HSPane.1}
}
#</Session>

