# ============================================================================
# --- Open the Design
# ============================================================================
#/design04/M28PT_F_layout02_vf/u2b10/data/r7f702540/6_layoutchk/MASTER_PG/02_Analog/02_Signal_route/PR02
#/design04/M28PT_F_layout02_vf/u2b10/usr/khangtran/U2B10/05_PV/wrappers01
#/design04/M28PT_F_layout02_vf/u2b10/data/r7f702540/6_layoutchk/v100_eco02/PL
#open_block /design04/M28PT_F_layout02_vf/u2b10/usr/khangtran/U2B10/01_DATA_PnR/f6931_1113a:100_init_design_SIGNAL_MS3.design;link;start_gui 
#open_block /design04/M28PT_E_layout02_vf/u2b6/usr/khangtran/U2B6/DATA_PnR/f5433_1112b:100_init_design_wEndCap_IO_CHANGE_PR01.design;start_gui
#/design04/M28PT_F_layout02_vf/u2b10/data/r7f702540/6_layoutchk/MASTER_PG/02_Analog
set_snap_setting -class {std_cell} -snap {litho}
set_snap_setting -class {metal_shape} -snap {litho}
set_snap_setting -class {placement_constraint} -snap {litho}
set_snap_setting -class {wiring_constraint} -snap {litho}
#==========================================
#============report_cell===================
#==========================================
proc  rp_cell {} {
      set b [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] full_name]
      set c [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] net.name]
      set d [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] layer_name]
      set e [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] bbox]
      set formatstr {%-80s %-25s %-25s %-25s}                  
      puts [format $formatstr "Pin name" "Net" "Layer" "bbox"]
            foreach b $b c $c d $d e $e {
                   puts [format $formatstr $b $c $d $e]
                                       }
                      }
#===========================================
#============created_shape_base_on_pin======
#===========================================
proc cr_shape {pin} {
    foreach_in_collection a [get_shapes -of_objects [get_pins $pin]]  {
      set b [get_attribute $a layer_name]
      set c [get_attribute [get_pins $pin] net.name]
      set d [get_attribute $a bbox]
        create_shape -shape_type path -layer $b -net $c -boundary $d
    }
}
#===========================================
#=======created_shape_base_on_layer=========
#===========================================
proc cr_shape_Metal {M1 M2} {
  set Cell_name [get_attribute [get_cells [get_sel]] full_name]
  foreach_in_collection name_net [get_pins -of_objects [get_cells $Cell_name] -f port_type==power||port_type==ground] {
      set col_net [get_attribute [get_pins $name_net] net.name]
      foreach_in_collection a [get_shapes -within [get_cells $Cell_name] -f owner.name==$col_net&&layer_name==$M1] {
        set d [get_attribute $a bbox]
        create_shape -shape_type path -net $col_net -layer $M2 -boundary $d 
      }
   }          
}
#==========================================
#=========copy_shape_x=====================
#==========================================
proc  cp_shx {lengh times} {
      set a [get_attribute [get_shapes [get_selection]] width]
      set k [expr $lengh + $a]
      copy_objects [get_selection] -x_pitch $lengh -delta [subst {$k 0}] -x_times $times
}
#==========================================
#=========copy_vias_x=====================
#==========================================
proc  cp_viax {lengh times} {
      set a [get_attribute [get_vias [get_selection]] width]
      set k [expr $lengh + $a]
      copy_objects [get_selection] -x_pitch $lengh -delta [subst {$k 0}] -x_times $times
}
#=========================================
#======copy_shape_y=======================
#=========================================
proc  cp_shy {lengh times} {
         set a [get_attribute [get_shapes [get_selection]] width]
        set k [expr $lengh + $a]
     set_snap_setting -enabled {false}
     copy_objects [get_selection] -y_pitch $lengh -delta [subst {0 $k}] -y_times $times
     set_snap_setting -enabled {true}
}
#=========================================
#======copy_vias_y=======================
#=========================================
proc  cp_viay {lengh times} {
      set a [get_attribute [get_vias [get_selection]] width]
      set k [expr $lengh + $a]
      set_snap_setting -enabled {false}
      copy_objects [get_selection] -y_pitch $lengh -delta [subst {0 $k}] -y_times $times
      set_snap_setting -enabled {true}
}

#=========================================
#========move_shape=======================
#=========================================
proc  mv_sh {x y} {
      move_objects [get_selection] -delta [subst {$x $y}]
                   }
#=========================================
#==========remove_shapes_vias=============
#=========================================
proc re_all {bbox} {
   remove_objects [get_shapes -intersect $bbox]
   remove_objects [get_shapes -within $bbox]
   remove_objects [get_vias -intersect $bbox]
   remove_objects [get_vias -within $bbox]
}
#=========================================
#==========remove_shapes_vias=============
#=========================================
proc re_viabbox {} {
   set bbox [get_attribute [get_placement_blockages [get_selection]] bbox]
   remove_objects [get_vias -intersect $bbox]
   remove_objects [get_vias -within $bbox]
   remove_objects [get_vias -touching $bbox]
}
#=========================================
#==========remove_vias====================
#=========================================
proc rm_viashap {} {
 set bbox [get_attribute [get_shapes [get_selection]] bbox]
 remove_objects [get_vias -quiet -within $bbox]
 remove_objects [get_vias -quiet -touching $bbox]
 remove_objects [get_vias -quiet -intersect $bbox]
}
#=========================================
#============fix_vias_x&y pitch===========
#=========================================
proc fix_via {x_pitch y_pitch} {
     set NameOfVias [get_attribute [get_vias [get_selection]] full_name]
     set_attribute -objects [get_vias $NameOfVias] -name x_pitch -value $x_pitch
     set_attribute -objects [get_vias $NameOfVias] -name y_pitch -value $y_pitch
}
#=========================================
#==========select_shapes==================
#=========================================
proc sel_shap {far} {
 set a [get_attribute [get_shapes [get_selection]] bbox]
 set b [lsort -decreasing $a]
 set d [sizeof_collection [get_shapes [get_selection]]]
 change_selection []
 set i 0
   while {$i < $d} {
      set c [lindex $b $i]
      set i [expr $i + $far + 1] 
      change_selection [get_shapes -touching [subst {$c}]] -add
  }
}
#=========================================
#==========created_via_array==============
#=========================================
proc v_array_PG {M2 M1 tag_name}  {
 foreach_in_collection a [get_shapes [get_sel]] {
  set_pg_via_master_rule VIA89_stripe -contact_code VIA89_1cut -orient R0 -cut_spacing {0.66 0.66}
  set_pg_via_master_rule VIA9AP_stripe -contact_code VIA9AP_1cut -orient R0 -cut_spacing {2 2}
  set b [get_attribute $a bbox]
  set net [get_attribute $a net.name]
  create_pg_vias -within_bbox $b -nets $net -from_layer $M2 -to_layer $M1 -tag $tag_name -allow_parallel_objects -via_masters {VIA89_stripe VIA9AP_stripe}
 }
}

proc gvx_7x7 {to_layer tag_name} {\
  set net_name [lsort -unique [get_attribute [get_selection] owner.name]]
  set layer_net [lsort -unique [get_attribute [get_selection] layer_name]]
  foreach_in_collection shape [get_shapes [get_selection]] {
   set_pg_via_master_rule VIA15_strip -contact_code {VIA12_1cut VIA23_1cut VIA23_1cut VIA34_1cut VIA45_1cut VIA56_1cut VIA67_1cut}
   set via_master [list VIA15_strip ]
   create_pg_vias -allow_parallel_objects -net $net_name -from_layers $layer_net -to_layers $to_layer -tag $tag_name -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters [subst {$via_master}] -drc check_but_no_fix
  }
}


proc v_array_PG_shield {to_layer tag_name} {\
     foreach_in_collection shape [get_shapes [get_selection]] {
        set net_name [get_attribute [get_nets -of [get_shapes $shape]] full_name]
        set layer_net [get_attribute [get_selection] layer_name]
        set_pg_via_master_rule VIA89_stripe -contact_code VIA89_1cut -orient R0 -cut_spacing {0.66 0.66}
        set via_master [list VIA12_LONG_V VIA23_LONG_V VIA34_LONG_V VIA45_LONG_V VIA89_stripe]
        create_pg_vias -allow_parallel_objects -insert_additional_vias -net $net_name -from_layers $layer_net -to_layers $to_layer -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters $via_master -tag $tag_name
     }
}

#==========================================
##=======created_via_array_signal==========
##=========================================
#proc v_array_Signal {M2 M1 } {
proc v_array_Signal {to_layer tag_name} {
 foreach_in_collection shape [get_shapes [get_selection]] {
        set net_name [get_attribute [get_nets -of [get_shapes $shape]] full_name]
        set layer_net [get_attribute [get_selection] layer_name]
        set via_master [list VIA12_LONG_V VIA23_LONG_V VIA34_LONG_V VIA45_LONG_V]
        create_pg_vias -allow_parallel_objects -insert_additional_vias -net $net_name -tag $tag_name  -from_layers $layer_net -to_layers $to_layer -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters $via_master
        #create_pg_vias -allow_parallel_objects -insert_additional_vias -net $net_name  -from_layers $M2 -to_layers $M1 -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters $via_master
 }    
}   

#=========================================
#========created_via_array_bbox===========
#=========================================
proc v_arraybbox {M2 M1} {
 set bbox [get_attribute [get_placement_blockages [get_selection]] bbox]
 set net [get_attribute [get_shapes -within [get_attribute [get_placement_blockages [get_selection]] bbox]] owner.name]
 create_pg_vias -within_bbox $bbox -nets $net -from_layer $M2 -to_layer $M1 -allow_parallel_objects -tag PLL
}
#=========================================
#================connect_PAD==============
#=========================================
proc c_pad {} {
  set name_cell [get_attribute [get_cell [get_sel]] full_name]
  set name_pin [get_attribute [get_pins -of_objects [get_cells [get_selection]]] full_name]
  set c [split $name_cell _]
  set e [llength $c]
  set net ""
  set i 2
   while {$i < $e} {
    set d [lindex $c $i]
    set i [expr $i + 1]
    if {$i==$e} {
       set net ${net}${d}
    } else {
       set net ${net}${d}_
      }
   }
   set type [get_attribute [get_nets $net] net_type]
   if {$type=="power"||$type=="ground"} {
   connect_pg_net -net $net [get_pins $name_pin]
   } elseif {$type=="signal"} {
   connect_net -net $net [get_pins $name_pin]
     }
}
#====================================
#====print origin $ net PAP of TEXT =
#====================================
proc rp_TEXT {} {
foreach_in_collection PAD [get_cells -within [get_attri [get_sel] bbox] -filter "base_name=~*PAD*"] {
 set net_name [get_attribute [get_pins -of_objects [get_cells $PAD]] net_name]
 set pad_origin [get_attri $PAD origin]
 set formatstr {%-12s %-12s %-25s %s}
   puts [format $formatstr "layouttext" \"$net_name\" $pad_origin "WMA"]
}
}
#========================================
#print report created P2P cellA of Probe=
#========================================
proc rp_cellA {refname} {
  foreach_in_collection cell_name [get_cells -within [get_attri [get_sel] bbox] -filter "base_name=~*PAD*"] {
   set num_shape [sizeof_collection [get_shapes -quiet -intersect [get_attri [get_cells $cell_name] bbox ]]]
   if {$num_shape!=0} {
    set CellA [get_attri [get_cell $cell_name] full_name]
    set CellB [get_attribute [get_cells -within [get_attri [get_sel] bbox] -filter "ref_name==$refname"] full_name]
    set sp [split $CellB /]
    set remark [lindex $sp end]
    set PinA [get_attribute [get_pins -of_objects [get_cells $cell_name]] full_name]
    set PinA_layer [get_attribute [get_pins -of_objects [get_cells $cell_name]] layer.name]
    set formatstr {%-5s %-18s %-23s %-10s}
    puts [format $formatstr $remark $CellA $PinA $PinA_layer]
   } 
  }
}
#====================================
#print report created P2P cellB 
#====================================
proc rp_cellB {refname} {
  foreach_in_collection cell_name [get_cells -within [get_attri [get_sel] bbox] -filter "ref_name==$refname"] {
    set CellB [get_attribute [get_cells $cell_name] full_name]
      set pin [get_pins -quiet -of_objects [get_cells $cell_name] -filter (port_type==power||port_type==ground||name==NGATE_V50||name==PGATE_V50)&&physical_status!=unrestricted]
          foreach PinB [get_attribute [get_pins -quiet $pin] full_name] {
                 set pinB_layer [get_attribute [get_pins -quiet $PinB] layer_name ]
                 set net [get_attribute [get_nets -quiet -of_objects [get_pins $PinB]] name]
                 set formatstr {%-23s %-40s %-15s %-20s %-20s}
                 puts [format $formatstr $CellB $PinB $pinB_layer $net 3]
          }
   }
}

#====================================
#print report created P2P cellC 
#====================================
proc rp_cellC {} {
  foreach_in_collection cell_name [get_cells [get_sel]] {
   set num_shape [sizeof_collection [get_shapes -quiet -intersect [get_attri [get_cells $cell_name] bbox ]]]
   if {$num_shape!=0} {
    set CellC [get_attri [get_cells $cell_name] full_name]
    set pin [get_pins -of_objects [get_cells $cell_name] -f port_type==power||port_type==ground]
     foreach PinC [get_attribute [get_pins -quiet $pin] full_name] {
      set PinC_layer [get_attribute [get_pins -quiet $PinC] layer_name]
      set formatstr {%-60s %-75s %-40s}
      puts [format $formatstr $CellC $PinC $PinC_layer]
     }
   }
  }
}
#===============================================
#====created shape base on pin sel cell v2.0 ===
#===============================================
proc cr_shape_sel_cell {} {
  foreach full_name_pin [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] full_name] {
     foreach_in_collection a [get_shapes -of_objects [get_pins $full_name_pin]]  {
      set layer_pin [get_attribute $a layer_name]
      set net_pin [get_attribute [get_pins $full_name_pin] net.name]
      set bbox [get_attribute $a bbox]
        create_shape -shape_type path -layer $layer_pin -net $net_pin -boundary $bbox
     }
  }
}
#===============================================
#============Fix Width shape ===================
#===============================================
proc w_shape {size} {
  set name_shape  [get_attribute  [get_shapes [get_selection]] full_name]
  set_attribute -objects [get_shapes $name_shape] -name width -value $size
}
#===============================================
#============Change Layer shape ================
#===============================================
proc c_Layer_shape {Mx} {
gui_change_layer -object [get_shapes [get_selection]] -layer $Mx
}
#===============================================
#============Change Nets name shape=============
#===============================================
proc c_Nets_Name {nets_name} {
  set_attribute -objects [get_shapes [get_selection]] -name owner -value [get_nets -design [current_block] -quiet $nets_name]
}
#===============================================
#============Change Routing Blockage============
#===============================================
proc c_BLK {name_blk} {
 change_selection [get_routing_blockages RB_${name_blk}]  
}
#===============================================
#============Change net name=====================
#===============================================
proc gchange_net_name {to_net} { \
  foreach_in_col SEL [get_sel ] {
    set type [get_attr $SEL object_class]
    if {$type=="via"} {
      set fr_net [get_attribute [get_vias $SEL ] owner]
      remove_from_net $fr_net [get_vias $SEL ]  -force
      add_to_net $to_net [get_vias $SEL]
    }
    if {$type=="shape"} {
      set fr_net [get_attribute [get_shapes $SEL ] owner]
      remove_from_net $fr_net [get_shapes $SEL ]  -force
      add_to_net $to_net [get_shapes $SEL]
    }
  }  
}    

#===============================================
#==selected shape from layer 7 to layer 9 ======
#===============================================
proc sel_shapM7M9 {net layer} {
  set cell [get_attribute [get_cells [get_sel]] full_name]
  change_sel [get_shapes -intersect [get_cells $cell] -f owner.name==$net&&layer_name==$layer]
  change_sel [get_shapes -within [get_cells $cell] -f owner.name==$net&&layer_name==$layer] -add
  change_sel [get_vias -intersect [get_cells $cell] -f owner.name==$net&&lower_layer_name==$layer] -add
  change_sel [get_vias -within [get_cells $cell] -f owner.name==$net&&lower_layer_name==$layer] -add
        }
#===============================================
#========selected shape from layer AP ========== 
#===============================================
proc  sel_shapAP {net layer} {
  set cell [get_attribute [get_cells [get_sel]] full_name]
  change_sel [get_shapes -intersect [get_cells $cell] -f owner.name==$net&&layer_name==$layer]
  change_sel [get_shapes -within [get_cells $cell] -f owner.name==$net&&layer_name==$layer] -add
  change_sel [get_vias -intersect [get_cells $cell] -f owner.name==$net&&upper_layer_name==$layer] -add
  change_sel [get_vias -within [get_cells $cell] -f owner.name==$net&&upper_layer_name==$layer] -add
                }
#===============================================
#========selected shape tag<name>==== ========== 
#===============================================
proc sel_shapetag {tag} {
 change_selection [get_shapes -filter tag==$tag]
}
#===============================================
#========selected vias tag<name>================ 
#===============================================
proc sel_viastag {tag} {
 change_selection [get_vias -filter tag==$tag]
}

#================================================
##========remove vias&shape tag<name>============ 
##===============================================
proc remove_tag_patterns {tag} {
  change_selection [get_shapes -filter tag==$tag] -add
  chasge_selection [get_vias -filter tag==$tag] -add
  remove_object [get_selection]
}
#================================================
##========remove routing BLK===================== 
##===============================================
proc rm_blk {$name_RBLK} {
   remove_routing_blockages [get_routing_blockages $name_RBLK]
}

#====================================================
#========selected vias&shape output file<name.dump>==
#====================================================
proc sel_tag {tag name_file} {
 change_selection [get_shapes -filter tag==$tag] -add
  change_selection [get_vias -filter tag==$tag] -add
  write_routes -objects [get_selection] -output $name_file
  }
	proc sel_tag1 {tag_name} {
  change_selection [get_shapes -filter tag==$tag_name] -add
  change_selection [get_vias -filter tag==$tag_name] -add
}
#====================================================
#========gennerate <name.def>========================
#====================================================
proc gen_def {namefile} {
write_def -objects [get_selection] $namefile.def
}
#===============================================
#=====selected all shape differrnt Metal======== 
#===============================================
proc gsel_jumpsh {lay} {
set net [lsort -u [get_attribute [get_shapes [get_sel]] net.name]]
change_selection [get_shapes -f net.name==$net&&layer_name==$lay]
}
#===============================================
#========selemted PAD NET======================= 
#===============================================
proc sel_PAD {NET} {
change_selection [get_cells -hierarchical -f full_name=~PAD*$NET]
}
#===============================================
#========created Tag<name>======================= 
#===============================================
proc cr_tag {tag} {
set_attribute [get_selection] tag $tag
}
#===============================================
#========select ogri Pin======================== 
#===============================================
proc gxyg {} {
  gui_mouse_tool -start POINT_DEFINITION_TOOL -window [gui_get_current_window -types Layout -mru]
}
proc gxyp {} {
  set x [lindex [gui_get_region] 0]
  set y [lindex [gui_get_region] 1]
  puts "$x $y"
}
#===============================================
#===========remove routing blockage============= 
#===============================================
proc rm_Rblock {} {
remove_routing_blockages -all
}
#===============================================
#===========remove cell physical================ 
#===============================================
proc rm_cell_physical {} {
 remove_objects [get_cells -hierarchical -filter physical_status==unplaced]
}
#===============================================
#===========remove cell for_signal============== 
#===============================================
proc rm_StdCell {} {
remove_objects [get_cells -hierarchical -filter physical_status==unplaced||design_type==lib_cell||design_type==diode||design_type==filler]
}
#===============================================
#===========highligh Pin======================== 
#===============================================
proc hlpin {} {
  foreach_in_collection a [get_pins -of_objects [get_cells [get_selection]] -f "port_type==power||port_type==ground" ] {
    set b [get_attribute $a name]
    puts "$b"
    if {[string match VDD $b]} {
      gui_change_highlight -color green -collection $a
    } elseif {[string match PPWVREF $b]} {
      gui_change_highlight -color purple -collection $a
    } elseif {[string match VSS $b]} {
      gui_change_highlight -color blue -collection $a
    } elseif {[string match VSSPLL $b]} {
      gui_change_highlight -color green -collection $a
    } elseif {[string match AVDD $b]} {
      gui_change_highlight -color orange -collection $a
    } elseif {[string match VCC $b]} {
      gui_change_highlight -color yellow -collection $a
    } elseif {[string match VSSPLL $b]} {
      gui_change_highlight -color blue -collection $a
    } elseif {[string match VSSQ $b]} {
      gui_change_highlight -color blue -collection $a
    } elseif {[string match VCCPLL $b]} {
      gui_change_highlight -color light_orange -collection $a 
    } elseif {[string match VSSCA $b]} {
      gui_change_highlight -color purple -collection $a
    } elseif {[string match VCCA $b]} {
      gui_change_highlight -color light_orange -collection $a



 

    } else {
      puts "0"
    }
  }
}
#===============================================
#===========select shape M1-AP================== 
#===============================================
proc sel_shape1 {net layer} {
  set cell [get_attribute [get_cells [get_sel]] full_name]
  change_sel [get_shapes -intersect [get_cells $cell] -f owner.name==$net&&layer_name==$layer]
  change_sel [get_shapes -touching [get_cells $cell] -f owner.name==$net&&layer_name==$layer] -add
  change_sel [get_shapes -within [get_cells $cell] -f owner.name==$net&&layer_name==$layer] -add
        }
#===============================================
#===========turn on lightmode=================== 
#===============================================
proc lightmode {} {
#IC Compiler II version P-2019.03-SP3
 gui_set_var -name {read_pref_file} -value {true}
 gui_create_pref_key -category {ErrorBrowser} -key {view_mode} -value_type {string} -value {off}
 gui_create_pref_key -category {ErrorBrowser} -key {zoom_factor} -value_type {double} -value {5}
 gui_create_pref_key -category {RDLFlylines} -key {ObjType} -value_type {string} -value {RDL Bump}
 gui_create_pref_key -category {RulerTool} -key {Direction} -value_type {string} -value {X or Y}
 gui_create_pref_key -category {RulerTool} -key {Color} -value_type {color} -value {blue}
 gui_create_pref_key -category {__guiFiltersColumn} -key {namespaces} -value_type {string} -value {__guiFiltersColumn:}
 gui_create_pref_key -category {__guiFiltersSearch} -key {namespaces} -value_type {string} -value {__guiFiltersSearch:}
 gui_create_pref_key -category {layout} -key {colorBackground} -value_type {color} -value {white}
 gui_create_pref_key -category {layout} -key {colorDRCDefault} -value_type {color} -value {red}
 gui_create_pref_key -category {layout} -key {colorDRCSelection} -value_type {color} -value {magenta3}
 gui_create_pref_key -category {layout} -key {colorPAKOHard} -value_type {color} -value {green}
 gui_create_pref_key -category {layout} -key {colorSelected} -value_type {color} -value {mediumblue}
 gui_create_pref_key -category {layout} -key {hatchCellCore} -value_type {string} -value {BDiagPattern}
 gui_create_pref_key -category {layout} -key {hatchCellHardMacro} -value_type {string} -value {Dense7Pattern}
 gui_create_pref_key -category {layout} -key {hatchCellIO} -value_type {string} -value {FDiagPattern}
 gui_create_pref_key -category {layout} -key {layoutToolbarAutoApply} -value_type {bool} -value {true}
 gui_set_var -name {read_pref_file} -value {false}
}
#===============================================
#===========turn on darkmode=================== 
#===============================================
proc darkmode {} {
gui_set_var -name {read_pref_file} -value {true}
gui_create_pref_key -category {ErrorBrowser} -key {view_mode} -value_type {string} -value {off}
gui_create_pref_key -category {ErrorBrowser} -key {zoom_factor} -value_type {double} -value {5}
gui_create_pref_key -category {RDLFlylines} -key {ObjType} -value_type {string} -value {RDL Bump}
gui_create_pref_key -category {RulerTool} -key {Direction} -value_type {string} -value {X or Y}
gui_create_pref_key -category {RulerTool} -key {Color} -value_type {color} -value {white}
gui_create_pref_key -category {__guiFiltersColumn} -key {namespaces} -value_type {string} -value {__guiFiltersColumn:}
gui_create_pref_key -category {__guiFiltersSearch} -key {namespaces} -value_type {string} -value {__guiFiltersSearch:}
gui_create_pref_key -category {layout} -key {colorPAKOHard} -value_type {color} -value {green}
gui_create_pref_key -category {layout} -key {hatchCellCore} -value_type {string} -value {BDiagPattern}
gui_create_pref_key -category {layout} -key {hatchCellHardMacro} -value_type {string} -value {Dense7Pattern}
gui_create_pref_key -category {layout} -key {hatchCellIO} -value_type {string} -value {FDiagPattern}
gui_create_pref_key -category {layout} -key {layoutToolbarAutoApply} -value_type {bool} -value {true}
gui_set_var -name {read_pref_file} -value {false}
gui_create_pref_key -category {layout} -key {colorBackground} -value_type {color} -value {black}
gui_create_pref_key -category {layout} -key {colorDRCDefault} -value_type {color} -value {red}
gui_create_pref_key -category {layout} -key {colorDRCSelection} -value_type {color} -value {magenta3}
gui_create_pref_key -category {layout} -key {colorSelected} -value_type {color} -value {white}
}
#==============================================
#==============report width and via===========
#=============================================
proc rp_w_v {} {
    set inf_width [get_attribute [get_shapes [get_selection]] width]
    set layer_name [get_attribute [get_shapes [get_selection]] layer_name]
    set inf_via [get_attribute [get_vias -intersect [get_shapes [get_selection]] -f upper_layer_name==$layer_name] array_size]
    set format_wv {%-25s%-25s}
    puts [format $format_wv "Width" "Via_array"]
    foreach inf_width $inf_width inf_via $inf_via {
         puts [format $format_wv $inf_width $inf_via]
    }
}

#===============================================
#=========created PBK for cell================== 
#===============================================
proc cr_PBK {bbox} {
 create_pg_region PLL -polygon [subst {$bbox}]
}

################checking the total shapes and vias with tag name######################
proc gwrite_module {name} {
        change_selection [get_shapes *]
        change_selection [get_vias *] -add
        set _com_1 [sizeof_collection [get_selection]]
        change_selection [get_shapes -filter "tag==AD0||tag==AD1||tag==AD2||tag==FLASH||tag==SYSTOP||tag==THS||tag==shield_AD0||tag==shield_AD1||tag==shield_AD2||tag==shield_FLASH||tag==shield_SYSTOP||tag==shield_THS"]
        change_selection [get_vias -filter "tag==AD0||tag==AD1||tag==AD2||tag==FLASH||tag==SYSTOP||tag==THS||tag==shield_AD0||tag==shield_AD1||tag==shield_AD2||tag==shield_FLASH||tag==shield_SYSTOP||tag==shield_THS"] -add
        set _com_2 [sizeof_collection [get_selection]]
   if {$_com_1==$_com_2} {
        change_selection [get_shapes -filter "tag==shield_$name"]
        change_selection [get_shapes -filter "tag==$name"] -add
        change_selection [get_vias -filter "tag==$name"] -add
        change_selection [get_vias -filter "tag==shield_$name"] -add
        set _time [clock format [clock seconds] -format %m%d%y]
        write_route -objects [get_selection] -output ${name}_${_time}.dump
        puts "####DONE##### --> write_route $name"
   } else {
        puts "####ERROR#### --> recheck inputs"
   }
}
################Routing Blockage creation for AD######################
proc gcr_blk { space rbname } {
  foreach_in_collection  sel [get_selection] {
     set bbox [get_attribute $sel bbox  ]
     set llaynum [get_attribute $sel layer_number ]
     set llx [lindex [lindex $bbox 0] 0]
     set lly [lindex [lindex $bbox 0] 1]
     set urx [lindex [lindex $bbox 1] 0]
     set ury [lindex [lindex $bbox 1] 1]
        if {$llaynum == 31} { set llay  {M1 M2}    }
        if {$llaynum == 32} { set llay  {M1 M2 M3} }
        if {$llaynum == 33} { set llay  {M2 M3 M4} }
        if {$llaynum == 34} { set llay  {M3 M4 M5} }
        if {$llaynum == 35} { set llay  {M4 M5 M6} }
        if {$llaynum == 36} { set llay  {M5 M6 M7} }
        if {$llaynum == 37} { set llay  {M6 M7} }
        if {$llaynum == 38} { set llay  {M8} }
        if {$llaynum == 39} { set llay  {M9} }
        if {$llaynum == 74} { set llay  {AP} }
          create_routing_blockage -boundary [subst {{[expr $llx -$space] [expr $lly -$space]} {[expr $urx + $space] [expr $ury +$space]}}] -layers $llay -name_prefix RB_${rbname}
  } 
}
################check via######################
proc check_via_distance {args} {
    parse_proc_arguments -args $args results

    set d   [expr $results(-dist) / 2]
    set net       $results(-stripe_net)
    #set ref       $results(-ref_name)
    set pin       $results(-pin_name)

    #puts "DBG: $d $net $ref $pin"
    puts "DBG: $d $net $pin"

    #set col_cells [get_cells -physical_context -filter "ref_name==$ref"]
    set col_cells [get_cells [get_sel]]
    set col_vias ""
    set col_cell_areas ""
    foreach_in_col ptn $col_cells {
      #echo $ptn
      if { $col_vias == "" } {
        set col_vias [resize_polygons -objects [get_vias -within [get_attribute $ptn boundary] -filter "owner.name==$net&&cut_layers.name==VIA5"] -size "0.1 $d 0.1 $d"]
        set col_cell_areas [resize_polygons -objects [get_attribute $ptn boundary] -size "0.1 -$d 0.1 -$d"]
      } else {
        set col_vias [compute_polygons \
                        -objects1 $col_vias \
                        -objects2 [resize_polygons -objects [get_vias -within [get_attribute $ptn boundary] -filter "owner.name==$net&&cut_layers.name==VIA5"] -size "0.1 $d 0.1 $d"] \
                        -operation OR]
        set col_cell_areas [compute_polygons -objects1 $col_cell_areas -objects2 [resize_polygons -objects [get_attribute $ptn boundary] -size "0.1 -$d 0.1 -$d"] -operation OR]
      }
    }

    set col_pins [resize_polygons -objects [get_shapes -of [get_pins -of $col_cells -filter "name==$pin"] -filter "layer_name==M5"] -size 0]
    set col_valid_via_area [compute_polygons -objects1 $col_vias -objects2 $col_cells -operation AND]

    set col_cell_areas [compute_polygons -objects1 $col_cells -objects2 $col_cell_areas -operation NOT]
    set col_valid_via_area [compute_polygons -objects1 $col_cell_areas -objects2 $col_valid_via_area -operation OR]

    set col_error_area [compute_polygons -objects1 $col_pins -objects2 $col_valid_via_area -operation NOT]

    if {[sizeof_col $col_error_area] != 0} {
      set split_rect [split_polygons $col_error_area -output poly_rect]
      foreach_in_collection spr $split_rect {
          create_routing_blockage -name_prefix "MISSED_POWER_${net}" -layers M5 -boundary [get_attr $spr bbox]
      }
    }
    gui_change_highlight -color yellow -collection [get_routing_blockages *MISSED_POWER_*]
}


define_proc_attributes check_via_distance -info "Check via disctance on SRAM/FLI" \
-define_args { \
 {-stripe_net "power/ground net name" AString string required} \
 {-dist "distance between vias" value float required} \
 {-pin_name "pin name of hard macros" string string required} }
 #{-ref_name "refarence name" value string required} }
##############################
proc show_via {pin_name} {
   change_selection [get_vias -intersect [get_pins $pin_name]] -add
   change_selection [get_vias -within [get_pins $pin_name]] -add
} 
 ##################################
proc arow_via {} {
   move_objects [get_vias [get_selection]] -rotate_by CW90
}
################################################
proc sel_cell {ref_name} {
  change_selection [get_cells -hierarchical -filter ref_name==$ref_name]
}
####################################################script analog signal#########################################################################
#===============================================
#=========created data for routing Blk========== 
#===============================================
proc gen_dataBLk {namedir} {
   write_floorplan -objects [get_selection] -force -output $namedir -nosplit
}
proc gc_shield {} {
change_selection [get_shapes -filter shape_use==core_wire] 
}

proc get_keyfile_ADC {anet pinname_in} { 
 set i 0
 foreach_in_col pin [get_flat_pins -of [get_nets $anet]] {
  set pin_namea [get_attr $pin cell.full_name]
  set pin_nameb [get_attr $pin name]
  set prc_net [lindex [split $anet /] end]
  set pin_out "$pin_namea:$pin_nameb"
  if {$pinname_in == $pin_out} {
  } else {
   echo "${prc_net}_0${i}   $prc_net   $pinname_in   $pin_out"
   incr i
   }
 }
}
proc get_FLI_keyfile {net} {
        set i 0
        set list_in ""
        set list_out ""
        set list_inout ""
        foreach_in_collection pin [get_flat_pins -of [get_nets $net]] {
            set net_name [lindex [split $net /] end]
            set _direction [get_attr $pin direction]
            set pin_name [get_attr $pin name]
            set cell_full_name [get_attr $pin cell.full_name]
            if {$_direction == "inout"} {
                lappend list_inout $pin_name $cell_full_name
            } elseif {$_direction == "in"} {
                lappend list_in $pin_name $cell_full_name
            } elseif {$_direction == "out"} {
                lappend list_out $pin_name $cell_full_name
            }
        }
        if {($list_inout != "") && ($list_in == "") && ($list_out != "")} {
            foreach {pin_inout cell_inout} $list_inout {
                lappend list_out $pin_inout $cell_inout
            }
        }
        if {($list_inout != "") && ($list_in != "") && ($list_out == "")} {
            foreach {pin_inout cell_inout} $list_inout {
                lappend list_in $pin_inout $cell_inout
            }
        }
        if {($list_inout != "") && ($list_in != "") && ($list_out != "")} {
            foreach {pin_inout cell_inout} $list_inout {
                lappend list_in $pin_inout $cell_inout
                lappend list_out $pin_inout $cell_inout
            }
        }
        if {($list_inout != "") && ($list_in == "") && ($list_out == "")} {
            foreach {pin_inout cell_inout} $list_inout {
                lappend list_in $pin_inout $cell_inout
                lappend list_out $pin_inout $cell_inout
            }
        }
        foreach {pin_out cell_out} $list_in {
                foreach {pin_in cell_in} $list_out {
                        set output_pin "${cell_in}:${pin_in}"
                        set input_pin "${cell_out}:${pin_out}"
                        lappend checklist "${input_pin}_${output_pin}"
                        set checkname "${output_pin}_${input_pin}"
                        if {[lsearch -exact $checklist $checkname] > 0} { } else {
                        if { $output_pin ne $input_pin } {
                        echo "${net_name}_0${i}   $net   $output_pin   $input_pin"
                        incr i
                        }
                        }
                }
        }
}
########
proc c_Layer_BLK {Mx} {
set_attribute -objects [get_routing_blockages [get_selection]] -name layer -value [get_layers $Mx]
}
### change_name_blk##
proc gc_change_name_BLK {name_net} {
 foreach blk [get_attribute [get_routing_blockages [get_selection]] full_name] {
   set nume_blk [lindex [split $blk _] end]
   set_attribute -objects [get_routing_blockages $blk] -name name -value RB_PL_${name_net}_${nume_blk}
 }
}
#######show name IO/PAD from pin
proc gl_show_IO_name {} {
 foreach IO_name [get_attribute [get_cells -of_objects  [get_pins [get_selection]]] full_name] {
  puts $IO_name
 }
}

proc sel_alldiff_shape {lay} {
set net [lsort -u [get_attribute [get_shapes [get_sel]] net.name]]
change_selection [get_shapes -f net.name==$net&&layer_name==$lay]
}
################via for signal############
proc gcreate_vias_hori {to_layer shape_use tag} {\
foreach_in_collection shape [get_shapes [get_selection]] {
set net_name [get_attribute [get_nets -of [get_shapes $shape]] full_name]
set layer_net [get_attribute [get_selection] layer_name]
set_pg_via_master_rule VIA89_stripe -contact_code VIA89_1cut -orient R0 -cut_spacing {0.66 0.66}
set via_master [list VIA12_LONG_H VIA23_LONG_H VIA34_LONG_H VIA45_LONG_H VIA89_stripe]
create_pg_vias -allow_parallel_objects -insert_additional_vias -net $net_name -from_layers $layer_net -to_layers $to_layer -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters $via_master -mark_as $shape_use -tag $tag 
}
}

proc gcreate_vias_ver {to_layer shape_use tag} {\
foreach_in_collection shape [get_shapes [get_selection]] {
set net_name [get_attribute [get_nets -of [get_shapes $shape]] full_name]
set layer_net [get_attribute [get_selection] layer_name]
set_pg_via_master_rule VIA89_stripe -contact_code VIA89_1cut -orient R0 -cut_spacing {0.66 0.66}
set via_master [list VIA12_LONG_V VIA23_LONG_V VIA34_LONG_V VIA45_LONG_V VIA89_stripe]
create_pg_vias -allow_parallel_objects -insert_additional_vias -net $net_name -from_layers $layer_net -to_layers $to_layer -within_bbox [ get_attribute [get_shapes $shape] bbox] -via_masters $via_master -mark_as $shape_use -tag $tag
}
} 

############check sort site row############
proc gcheck_short_row {} {
  foreach_in_collection SR_name [get_site_rows unit_*] {
   set bbox [get_attribute $SR_name bbox]
   change_selection -add [get_routing_blockages -intersect $bbox -quiet]
  }
}
#################sel layer BLK########
proc gsel_BLK_layer {layer} {
change_selection qget_routing_blockages -filter layer_name==$layer]
}
#################################
proc gread_DRC {name_file name_error} {
read_drc_error_file -file $name_file -error_data $name_error
}
proc gread_ERROR {dir} {
        foreach folder [glob -directory $dir -type d *] {
                set cell_name [lindex [split $folder /] end]
                foreach error_file [glob -directory $folder *.db] {
                        set error_mode_full [lindex [split $error_file /] end]
                        set error_mode [lindex [split $error_mode_full .] 0]
                        set name "${cell_name}:${error_mode}"
                        read_drc_error_file -error_data $name -file $error_file
                }
        }
}
proc gcheck_lvs_floating_shield {} {
check_lvs -checks {floating_routes} -nets {VSS A0VSS A1VSS A2VSS A3VSS ADSVSS ACYVSS AFCVSS PLLVSS SYSVCC}
}
proc gcheck_lvs_ANets {Analog_U2B6} {
check_lvs -nets $Analog_U2B6 -open_reporting detailed -check_child_cells true -max_errors 0
}
proc gcheck_lvs_open_shield {} {
check_lvs -open_reporting detailed -nets {VSS A0VSS A1VSS A2VSS A3VSS ADSVSS ACYVSS AFCVSS PLLVSS SYSVCC} -check_child_cells true -max_errors 0
}
#################release dump####
proc gwrite_module {name} {
        change_selection [get_shapes *]
        change_selection [get_vias *] -add
        set _com_1 [sizeof_collection [get_selection]]
        change_selection [get_shapes -filter "tag==PL_AD0||tag==PL_AD0_shield||tag==PL_AD1||tag==PL_AD1_shield"]
        change_selection [get_vias -filter "tag==PL_AD0||tag==PL_AD0_shield||tag==PL_AD1||tag==PL_AD1_shield"] -add
        set _com_2 [sizeof_collection [get_selection]]
   if {$_com_1!=$_com_2} {
        set temp "_shield"
        change_selection [get_shapes -filter "tag==PL_$name"]
        change_selection [get_shapes -filter "tag==PL_$name$temp"] -add
        change_selection [get_vias -filter "tag==PL_$name"] -add
        change_selection [get_vias -filter "tag==PL_$name$temp"] -add
        set _time [clock format [clock seconds] -format %m%d%y]
        write_route -objects [get_selection] -output ${name}_${_time}.dump
        puts "####DONE##### --> write_route $name"
   } else {
        puts "####ERROR#### --> recheck inputs"
   }
}
