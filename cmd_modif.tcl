# ============================================================================
# # --- Open the Design
# # ============================================================================
#open_block ./DATA_PnR/f5090_1113a/u2a6_lib:100_init_design_wEndCap_Tap_PAD_for_CHECKING ; link ; start_gui
#==========================================
#============report_cell===================
#==========================================
proc  rp_cell {} {
      set b [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] full_name]
      set c [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] net.name]
      set d [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] layer_name]
      set e [get_attribute [get_pins -of_objects [get_cells [get_sel]] -f port_type==power||port_type==ground] bbox]
      set formatstr {%-80s%-25s%-25s%-25s}                  
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
proc v_array {M2 M1} {
 foreach_in_collection a [get_shapes [get_sel]] {
  set_pg_via_master_rule VIA89_stripe -contact_code VIA89_1cut -orient R0 -cut_spacing {0.66 0.66}
  set_pg_via_master_rule VIA9AP_stripe -contact_code VIA9AP_1cut -orient R0 -cut_spacing {2 2}
  set b [get_attribute $a bbox]
  set net [get_attribute $a net.name]
  create_pg_vias -within_bbox $b -nets $net -from_layer $M2 -to_layer $M1 -allow_parallel_objects -tag PLL -via_masters {VIA89_stripe VIA9AP_stripe}
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
  change_selection [get_vias -filter tag==$tag] -add
  remove_object [get_selection]
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
#===============================================
#========selected PAD NET======================= 
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
#===============================================
#=========created PBK for cell================== 
#===============================================
proc cr_PBK {bbox} {
 create_pg_region PLL -polygon [subst {$bbox}]
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
