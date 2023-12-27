# ============================================================================
# --- Open the Design INNOVUS tool
# ============================================================================
#/home/ftv_training/2022_Sep_Training/Khangne
#source /home/flow_TimingClosure/Environment/02_Script/TCL/convert_icc_to_invs_insertBuffer.tcl
source /home/flow_TimingClosure/Environment/02_Script/TCL/convert_icc_to_invs_insertBufferold.tcl 
dbget head.topCells.name
#global
#set lefDefOutVersion 6.0
#=========================================
proc grpCell {type} {
    foreach Insts [dbGet selected.] {
        set pgPinName   [dbGet $Insts.pgInstTerms.name]
        set pgnetName   [dbGet $Insts.pgInstTerms.net.name]
        set sgPinName   [dbGet $Insts.InstTerms.name]
        set sgnetName   [dbGet $Insts.InstTerms.net.name]
        set tycellname  [dbGet $Insts.cell.name]
        set formatstr   {%-50s %-25s %-25s}
        puts [format $formatstr "Pin name" "CellType"  "Net name"]
        if {$type=="power"} {
            foreach A $pgPinName B $tycellname  C $pgnetName {
                puts [format $formatstr $A $B $C]
            }
        }
        if {$type=="signal"} {
            foreach A $sgPinName B $tycellname C $sgnetName {
                puts [format $formatstr $A $B $C]
            }
        }
    }
}
######################################
proc cr_shape_sel_cell {} {
 foreach full_name_pin [get_object_name [get_pg_pins -of_objects [get_cells [dbget selected.name]]]] {
     #set layer_pin [get_db pg_pin:$full_name_pin .pg_base_pin.physical_pins.layer_shapes.layer.name]
     set net_pin [get_db pg_pin:$full_name_pin .net.name]    
     #set bbox [dbTransform -localPt [dbGet selected.cell.pgTerms.pins.allShapes.shapes.rect] -inst [dbGet selected]]
     #set bbox    [get_db pg_pin:$full_name_pin .pg_base_pin.physical_pins.layer_shapes.shapes.polygon] 
     #set bbox [dbTransform -localPt [get_db pg_pin:$full_name_pin .pg_base_pin.physical_pins.layer_shapes.shapes.rect] -inst [dbGet selected]]
   foreach bbox [dbTransform -localPt [get_db pg_pin:$full_name_pin .pg_base_pin.physical_pins.layer_shapes.shapes.rect] -inst [dbGet selected]] {
     foreach layer_pin [get_db pg_pin:$full_name_pin .pg_base_pin.physical_pins.layer_shapes.layer.name] {
       add_shape -shape None -layer $layer_pin -net $net_pin -patch $bbox
     }
   }
 }
}
#==========================================
#=========copy_shape_x/y=====================
#==========================================
proc  cp_shx {lengh times} { 
   set NumWidth [get_db [dbget selected.] .width]
   set RelLengh [expr $lengh + $NumWidth]
   editCopy $RelLengh 0 -times $times
   deselectAll
}

#editDelete -type Regular	remove all shape.
#==========================================
#=========copy_shap_y=====================
#==========================================
proc  cp_shy {lengh times} {
   set NumWidth [get_db [dbget selected.] .width]
   set RelLengh [expr $lengh + $NumWidth]
   editCopy 0 $RelLengh -times $times
   deselectAll
}
#=========================================
#======move_shape=======================
#=========================================
proc mv_shape { x y } {	 
      if {[dbGet selected.objType] == "inst"} {
     move_obj -selected -direction right -distance $x
     move_obj -selected -direction up -distance $y
   } else {
      editMove -dx $x -dy $y
   }
}	
#=========================================
##======channge_nets_name=================
##========================================
proc gchange_NET {NET} {  	
  editChangeNet -to $NET	
}	
#=========================================
#======creted_VIA=======================
#=========================================
proc v_array_Signal { fr_layer to_layer TagName} { 	
set shape_select  [dbget selected.]	
foreach shape $shape_select {	
        set net_name [dbGet $shape_select.net.name]
	set bbox_llx [format %.3f [dbget $shape.box_llx]]
	set bbox_lly [format %.3f [dbget $shape.box_lly]]
	set bbox_urx [format %.3f [dbget $shape.box_urx]]
	set bbox_ury [format %.3f [dbget $shape.box_ury]]
	setViaGenMode -area_only true
	editPowerVia \
	-add_vias 1 \
	-orthogonal_only 0 \
	-bottom_layer  $fr_layer \
	-top_layer $to_layer \
        -create_via_on_signal_pins 1 \
	-area [subst { $bbox_llx $bbox_lly $bbox_urx $bbox_ury }] 
        deselectAll
        editSelect -area [subst { $bbox_llx $bbox_lly $bbox_urx $bbox_ury }] -object_type Via -net $net_name 
        set_db selected .user_class $TagName 
	}
setViaGenMode -area_only false	
}	

proc gcreate_via {to_layer} {
    foreach shape [dbGet selected.] {
        set net_name    [dbGet $shape.net.name]
        set layer_name  [dbGet $shape.layer.name]
        set box_name    [dbGet $shape.box]
        if {$to_layer!="AP"} {
            set s_to_layer [lindex [split $to_layer "M"] 1]
        } else {
            set s_to_layer "10"
        }
        if {$layer_name!="AP"} {
            set s_shape_layer [lindex [split $layer_name "M"] 1]
        } else {
            set s_shape_layer "10"
        }
        if {$s_shape_layer < $s_to_layer} {
            set t_layer $to_layer
            set b_layer $layer_name
        } else {
            set t_layer $layer_name
            set b_layer $to_layer
        }
        editPowerVia -skip_via_on_pin {Pad Cover Standardcell} \
                     -orthogonal_only 0 \
                     -area $box_name \
                     -top_layer $t_layer \
                     -bottom_layer $b_layer \
                     -net $net_name \
                     -add_vias 1 \
                     -selected_wires 1
    }
}
#======================================
#======creted_VIA_7X7==================
#======================================
proc gv_via7x7 { } {
    set net_name [get_db selected .net.name]
    regexp {{(.+)}} "[dbGet selected.box]" full_match bbox
    set wires [dbGet [dbGet -p1 top.nets.name $net_name].sWires]
    set box_collection [dbGet $wires.box]
    set temp [lsearch $box_collection $bbox]
    set box_collection [lreplace $box_collection $temp $temp ]
    set intersection_collection [dbShape $bbox AND $box_collection]
    puts $intersection_collection
    setEditMode -drc_on 1 -keep_via 0
    setViaGenMode -viarule_preference {VIAGEN12 VIAGEN23 VIAGEN34 VIAGEN45 \
                       VIAGEN56 VIAGEN67 VIAGEN78 VIAGEN89 VIAGEN9AP }
    setViaGenMode -preferred_vias_only keep -optimize_cross_via 1
    foreach _area $intersection_collection {
        set wire_collection {}
        deselectAll
        editSelect -area $_area -object_type Via -net $net_name
        editDelete -selected
        set wire_collection_temp [dbQuery -area $_area -objType {Wire sWire}]
        for {set count 0} {$count < [llength $wire_collection_temp]} {incr count} {
            if {[dbGet [lindex $wire_collection_temp $count].net.name] == $net_name} {
                lappend wire_collection [lindex $wire_collection_temp $count]
                }
            }
        set layer_collection [dbGet $wire_collection.layer.num]
        set layer_collection [lsort -decreasing $layer_collection]
        set topLayer_num [lindex $layer_collection 0]
        set botLayer_num [lindex $layer_collection [expr [llength $layer_collection] -1]]
        if {$topLayer_num != $botLayer_num} {
            editPowerVia -area $_area -add_vias 1 -bottom_layer "M$botLayer_num" -top_layer "M$topLayer_num" -split_vias 1
            }
        }
    setViaGenMode -reset
    setViaGenMode -area_only 0
}
gui_bind_key CTRL+V -cmd gv_via7x7

proc changeto_via7x7_selshape {TagName } {
        set net_name_collection [dbGet selected.net.name]
        set bbox_collection [dbGet selected.box]
        set count 0
        setEditMode -drc_on 1 -keep_via 0
        setViaGenMode -viarule_preference {VIAGEN12 VIAGEN23 VIAGEN34 VIAGEN45 \
                                                   VIAGEN56 VIAGEN67 VIAGEN78 VIAGEN89 VIAGEN9AP }
        setViaGenMode -preferred_vias_only keep -optimize_cross_via 1
        while {$count < [llength $net_name_collection]} { 
                set net_name [lindex $net_name_collection $count]
                set wire_collection ""
                set bbox [lindex $bbox_collection $count] 
                set wires [dbGet [dbGet -p1 top.nets.name $net_name].sWires]
                set box_collection [dbGet $wires.box]
                set temp [lsearch $box_collection $bbox]
                set box_collection [lreplace $box_collection $temp $temp ]
                set intersection_collection [dbShape $bbox AND $box_collection]
                foreach _area $intersection_collection {
                        set wire_collection {}
                        deselectAll
                        editSelect -area $_area -object_type Via -net $net_name
                        editDelete -selected
                        set wire_collection_temp [dbQuery -area $_area -objType {Wire sWire}]
                        for {set count1 0} {$count1 < [llength $wire_collection_temp]} {incr count1} {
                                if {[dbGet [lindex $wire_collection_temp $count1].net.name] == $net_name} {
                                        lappend wire_collection [lindex $wire_collection_temp $count1]
                                        }
                                }
                        set layer_collection [dbGet $wire_collection.layer.num]
                        set layer_collection [lsort -decreasing $layer_collection]
                        set topLayer_num [lindex $layer_collection 0]
                        set botLayer_num [lindex $layer_collection [expr [llength $layer_collection] -1]]
                        if {$topLayer_num != $botLayer_num} {
                                editPowerVia -area $_area -add_vias 1 -bottom_layer "M$botLayer_num" -top_layer "M$topLayer_num" -split_vias 1
                                deselectAll
                                editSelect -area $_area -object_type Via -net $net_name
                                set_db selected .user_class $TagName 
                                }
                        }
                incr count
                }
                setViaGenMode -reset
                setViaGenMode -area_only 0
}


#=========================================
##=====out_def_file=======================
##========================================
proc def_file { def_name } {	
deselectAll	
editSelect -net *	
editSelectVia -net *	
defOut -selected -routing $def_name	
}	
#========================================
##=====created tag=======================
##=======================================
proc cr_tag {TagName} {
 set_db selected .user_class $TagName 
}
#=========================================
#========select Tag_name==================
#=========================================
#set lefDefOutVersion 6.0
proc sel_tag {TagName FileName} {
  set lefDefOutVersion 6.0
  deselectAll
  editSelect -subclass $TagName
  editSelectVia -subclass $TagName
  defOutBySection -selected -noDieArea -specialNetrouting -specialNets -specialRouteUserClass "$TagName" $FileName.def
}
proc sel_tag1 {TagName} {
  deselectAll
  editSelect -subclass $TagName
  editSelectVia -subclass $TagName
}
#=========================================
#==========Dump data======================
#=========================================
proc gwrite_module {name} {
 deselectAll
 #set lefDefOutVersion 6.0
 editSelect -net *
 editSelectVia -net *
 set com_1 [llength [dbget selected.]]
 editSelect -subclass PL_AD1;editSelect -subclass PL_AD1_shield;editSelect -subclass PL_AD2;editSelect -subclass PL_AD2_shield; \
 editSelect -subclass PL_AD3;editSelect -subclass PL_AD3_shield;editSelect -subclass PL_ADS;editSelect -subclass PL_ADS_shield; \
 editSelect -subclass PL_FLASH;editSelect -subclass PL_FLASH_shield;editSelect -subclass PL_SYSTOP;editSelect -subclass PL_SYSTOP_shield; \
 editSelect -subclass PL_FCMP;editSelect -subclass PL_FCMP_shield;editSelect -subclass PL_ACY;editSelect -subclass PL_ACY_shield; \
 editSelect -subclass PL_THS;editSelect -subclass PL_THS_shield;editSelect -subclass PL_ADA;editSelect -subclass PL_ADA_shield; \
 editSelect -subclass PL_VBIAS;editSelect -subclass PL_VBIAS_shield;editSelect -subclass PL_AD0;editSelect -subclass PL_AD0_shield
 editSelectVia -subclass PL_AD1;editSelectVia -subclass PL_AD1_shield;editSelectVia -subclass PL_AD2;editSelectVia -subclass PL_AD2_shield; \
 editSelectVia -subclass PL_AD3;editSelectVia -subclass PL_AD3_shield;editSelectVia -subclass PL_ADS;editSelectVia -subclass PL_ADS_shield; \
 editSelectVia -subclass PL_FLASH;editSelectVia -subclass PL_FLASH_shield;editSelectVia -subclass PL_SYSTOP;editSelectVia -subclass PL_SYSTOP_shield; \
 editSelectVia -subclass PL_FCMP;editSelectVia -subclass PL_FCMP_shield;editSelectVia -subclass PL_ACY;editSelectVia -subclass PL_ACY_shield; \
 editSelectVia -subclass PL_THS;editSelectVia -subclass PL_THS_shield;editSelectVia -subclass PL_ADA;editSelectVia -subclass PL_ADA_shield; \
 editSelectVia -subclass PL_VBIAS;editSelectVia -subclass PL_VBIAS_shield;editSelectVia -subclass PL_AD0;editSelectVia -subclass PL_AD0_shield
 set com_2 [llength [dbget selected.]]
 if {$com_1==$com_2} {
  deselectAll
  set temp "_shield"
  editSelect -subclass PL_$name
  editSelect -subclass PL_$name$temp
  editSelectVia -subclass PL_$name
  editSelectVia -subclass PL_$name$temp
  set _time [clock format [clock seconds] -format %m%d%y]
  defOutBySection -selected -noDieArea -specialNetrouting -specialNets -specialRouteUserClass "PL_$name" ${name}_${_time}.def
  defOutBySection -selected -noDieArea -specialNetrouting -specialNets -specialRouteUserClass "PL_$name$temp" ${name}${temp}_${_time}.def
  puts "####DONE##### --> write_route $name"
 } else {
    puts "####ERROR#### --> recheck inputs"
   }
}
#=========================================
#==========show_inf=============
#=========================================
proc Inf {} {
 setDbGetMode -displayformat table
 dbget selected.??
}
#=========================================
#==========create BLK=====================
#=========================================
proc gcr_blk {space rbname} {
   set shape_select  [dbget selected.]
   foreach sel $shape_select {
    set bbox    [dbget $sel.box] 
    set llaynum [dbget $sel.layer.num]
    set llx [lindex [lindex $bbox 0] 0]
    set lly [lindex [lindex $bbox 0] 1]
    set urx [lindex [lindex $bbox 0] 2]
    set ury [lindex [lindex $bbox 0] 3]
      if {$llaynum == 1}  { set llay  {M1 M2}    }
      if {$llaynum == 2}  { set llay  {M1 M2 M3} }
      if {$llaynum == 3}  { set llay  {M2 M3 M4} }
      if {$llaynum == 4}  { set llay  {M3 M4 M5} }
      if {$llaynum == 5}  { set llay  {M4 M5 M6} }
      if {$llaynum == 6}  { set llay  {M5 M6 M7} }
      if {$llaynum == 7}  { set llay  {M6 M7} }
      if {$llaynum == 8}  { set llay  {M8} }
      if {$llaynum == 9}  { set llay  {M9} }
      if {$llaynum == 10} { set llay  {AP} }
        createRouteBlk -box [subst {{[expr $llx -$space] [expr $lly -$space]} {[expr $urx + $space] [expr $ury +$space]}}] -layer $llay -name RB_${rbname}
   }
}
##############################################
proc crt_BLK {SpacingSize RBname} {
        set i 0
        set net_name [lindex [dbGet selected.net.name] 0]
        set net_pointer [dbGet -p1 top.nets.name $net_name]
        set wires_collection [dbGet selected]
        set wires_box_collection [dbGet $wires_collection.box]
        set wires_layer_collection [dbGet selected.layer.num]
        set fullnet_box_collection [dbGet $net_pointer.sWires.box]
        set collection_length [llength $wires_collection]
        set inst_box_collection [dbGet $net_pointer.InstTerms.inst.box]
        for {set count 0} {$count < $collection_length} {incr count} {
                set RB_box      [lindex $wires_box_collection $count]
                set RB_layer    [lindex $wires_layer_collection $count]
                set RBbox [dbShape $RB_box SIZE $SpacingSize]
                lappend RBbox_list $RBbox
                if {$RB_layer == 1}  { set llay  {M1 M2}     }
                if {$RB_layer == 2}  { set llay  {M1 M2 M3}  }
                if {$RB_layer == 3}  { set llay  {M2 M3 M4}  }
                if {$RB_layer == 4}  { set llay  {M3 M4 M5}}
                if {$RB_layer == 5}  { set llay  {M4 M5 M6}  }
                if {$RB_layer == 6}  { set llay  {M6}  }
                if {$RB_layer == 7}  { set llay  {M7}  }
                if {$RB_layer == 8}  { set llay  {M8}  }
                if {$RB_layer == 9}  { set llay  {M9}  }
                if {$RB_layer == 10} { set llay  {AP}  }
                foreach layer $llay {
                  createRouteBlk -box $RBbox  -layer $layer -name RB_${RBname}_$i
                incr i
                 }
                }
        set intersection_area_information(area) ""
        set fullnet_box_collection_00 $fullnet_box_collection
        for {set count1 0} {$count1 < $collection_length} {incr count1} {
                set wire_box [lindex $wires_box_collection $count1]
                set position [lsearch $fullnet_box_collection_00 $wire_box]
                set fullnet_box_collection_00 [lreplace $fullnet_box_collection_00 $position $position]
                set intersection [dbShape $wire_box AND $fullnet_box_collection_00]
                if {$intersection != ""} {
                  for {set count2 0} {$count2 < [llength $intersection]} {incr count2} {
                          set intersection_area [lindex $intersection $count2]
                          if {[lsearch $intersection_area_information(area) $intersection_area] == -1} {
                                  lappend intersection_area_information(area) $intersection_area
                                  set layer_list [dbGet [dbGet -p1 [dbQuery -objType sWire -area $intersection_area].net {.name == $net_name}].layer.num]
                                  set layer_list [lsort -decreasing $layer_list]
                                  lappend intersection_area_information($intersection_area,to_layer)      [lindex $layer_list 0]
                                   lappend intersection_area_information($intersection_area,from_layer)    [lindex $layer_list [expr [llength $layer_list] - 1]]
                          }
                 }
               }
        }
        foreach _area $intersection_area_information(area) {
                for {set count3 [expr $intersection_area_information($_area,from_layer) + 1]} {$count3 < [expr $intersection_area_information($_area,to_layer) - 1]} {incr count3} {
                        set temp [dbShape $_area SIZE $SpacingSize]
                        createRouteBlk -box $temp -layer M$count3 -name RB_${RBname}
                }
       }
}
#=========================================
#==========change BLK=====================
#=========================================
proc c_BLK {name_blk} {
 deselectAll
 selectRouteBlk RB_${name_blk}*
}
#=========================================
#==========Gen_data BLK===================
#=========================================
proc gen_dataBLkVer1 {name_blk} {
 deselectAll
 set i 0
 set dir [file normalize [file dirname [file normalize [info script]]]/]
 set timeline [clock format [clock seconds] -format %y%m%d]
 set out [open "$dir/RB_${name_blk}_${timeline}.tcl_toINN" w+]
 selectRouteBlk RB_${name_blk}*
 foreach rblkg [get_db [dbget selected.]] {
             set name [get_db $rblkg .name]
             set layer [get_db $rblkg .layer.name]
             if {[get_db $rblkg .shapes.type] == "rect"} {
                 set box [get_db $rblkg .shapes.rect]
             } elseif {[get_db $rblkg .shapes.type] == "poly"} {
                 set box [get_db $rblkg .shapes.polygon]
             } else {
                 set box "-"
             }
             puts $out  "createRouteBlk -layer $layer -name $name\_$i -box $box"
             incr i
        }
close $out
puts "\033\[2;32mCreated data:\033\[1;34mRB_${name_blk}_${timeline}.tcl_toINN\033\[1;32m Successfully\033\[0m"
}
####################################################
proc gen_dataBLkVer2 {name_blk dir} {
 deselectAll
# set lefDefOutVersion 6.0
 set timeline [clock format [clock seconds] -format %y%m%d]
 selectRouteBlk RB_${name_blk}*
 defOutBySection -selected  -rBlockages -noComps -noDieArea -noNets -no_virtual_trim $dir/RB_${name_blk}_${timeline}.def_toINN
}
####################################################
proc gen_dataBLkVer3 {name_blk dir} {
 deselectAll
 set timeline [clock format [clock seconds] -format %y%m%d]
 selectRouteBlk ${name_blk}*
 writeFPlanScript -selected -fileName $dir/${name_blk}_${timeline}.tcl_toINN
 puts "\033\[2;32mCreated data:\033\[1;34mRB_${name_blk}_${timeline}.tcl_toINN\033\[1;32m Successfully\033\[0m"
}
#=========================================
#==========change Layer shape=============
#=========================================
proc c_Layer_shape {Mx} {
   editChangeLayer -layer_horizontal $Mx -layer_vertical $Mx
}
#=========================================
#==========change Width_shape=============
#=========================================
proc w_shape {size} {
  editChangeWidth -width_horizontal $size -width_vertical $size
}
#=========================================
#=====Get_keyformat=======================
#=========================================
proc get_CrPinToPinVer1 {constr dir} {
 set indir [open "/design04/M28PT_G_layout02_vf/u2b24/usr/khangtran/U2B24E/03_INNOVUS/analog_net_top.list" r]
 set file_data [read $indir]
 set outdir [open "$dir/pin_to_pin_spec.txt" w+] 
 set list_net [split $file_data "\n"]
 puts $outdir "IGNORE_PIN_DIRECTION"
 foreach net $list_net {
     set pin [dbGet [dbGet -p1 top.nets.name $net ].instTerms.name ]
     foreach pin_name $pin {
         set direction [get_db [get_db pins $pin_name] .direction]
         if {($direction == "in")||($direction == "inout")} {
             set pin_tmp $pin_name
             set pin_cell_tmp [get_db [get_db pins $pin_name] .inst.name]
             break
         }
     }
     foreach pin_name $pin {
         set direction [get_db [get_db pins $pin_name] .direction]
         if {($direction == "inout")} {
             set pin_cell [get_db [get_db pins $pin_name] .inst.name]
             puts $outdir  "$pin_cell_tmp $pin_tmp MAX $constr DRIVER $pin_cell $pin_name"
         }
     }
 }
close $indir
close $outdir
}
####################################
proc get_CrPinToPinVer2 {constr dir} {
     set indir [open "/design04/M28PT_G_layout02_vf/u2b24/usr/khangtran/U2B24E/03_INNOVUS/analog_net_top.list" r]
     set file_data [read $indir]
     set outdir [open "$dir/pin_to_pin_spec.txt" w+]
     set data [split $file_data "\n"]
     puts $outdir "IGNORE_PIN_DIRECTION"
     foreach list_net $data {
         set count       0
         set list_in     ""
         set list_out    ""
         set list_inout  ""
         if {$list_net eq ""} { } else {
           foreach pin [dbGet [dbGet -p top.nets.name $list_net].allTerms] {
              if {[dbGet $pin.objType] == "instTerm"} {
                 set _direction "[get_db [get_db pins $pin] .direction]"
                 set net_name  [lindex [split $list_net /] end]
                 set pin_name  "[dbGet $pin.defName]"
                 set cell_name "[dbGet $pin.inst.name]"
                if {$_direction == "inout"} {
                    lappend list_inout $pin_name $cell_name
                 } elseif {$_direction == "out"} {
                   lappend list_out $pin_name $cell_name
                 } elseif {$_direction == "in"} {
                   lappend list_in $pin_name $cell_name
                 }
             }
          }
        }
     if {($list_inout != "") && ($list_in != "") && ($list_out == "")} {
       foreach {pin_inout cell_inout} $list_inout {
            lappend list_out $pin_inout $cell_inout
       }
     } elseif {($list_out != "") && ($list_inout != "")} {
        foreach {pin_inout cell_inout} $list_inout {
         lappend list_in $pin_inout $cell_inout
        }
       } elseif {($list_out == "") && ($list_in == "")} {
         set flat 0
         foreach {pin_inout cell_inout} $list_inout {
           if {$flat == 0} {
            lappend list_out $pin_inout $cell_inout
            set flat 1
           } else {
             lappend list_in $pin_inout $cell_inout
            }
         }
     } else {}
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
         set output_pin "${cell_in} ${pin_in}"
         set input_pin "${cell_out} ${pin_out}"
         lappend checklist "${input_pin}_${output_pin}"
         set checkname "${output_pin}_${input_pin}"
         if {[lsearch -exact $checklist $checkname] > 0} { } else {
           if { $output_pin ne $input_pin } {
            puts $outdir "$output_pin  MAX  $constr  DRIVER  $input_pin"
           }
         }
        }
   }

    }
close $indir
close $outdir
}

####################################
proc get_PintoPin_ADC {anet IPnameA constr} {
  foreach pin [dbGet [dbGet -p1 top.nets.name $anet].instTerms.defName] {
    set Pinname_A "$IPnameA/$pin"
  }
  set pinB [dbGet [dbGet -p1 top.nets.name $anet ].instTerms.name ] 
  foreach Pinname_B $pinB {
   set direction [get_db [get_db pins $Pinname_B] .direction]
   if {($direction == "in")||($direction == "inout") } {
     set IPnameB [get_db [get_db pins $Pinname_B] .inst.name]
     set tempA "$IPnameA $Pinname_A"
     set tempB "$IPnameB $Pinname_B"
    if {$tempA == $tempB} {
    } else {
      puts  "$tempA MAX $constr DRIVER $tempB"
     }
   }
  }
} 
#=========================================
#=========Sel_ALLshape====================
#=========================================
proc gsel_Allshape {} {
  editSelect -object_type Wire
}
#=========================================
#=========Selecte Shape/Vias/Pin==========
#=========================================
proc sel_shape {} {
  set NetName [get_db [dbget selected.] .net.name]
  editSelect -net $NetName  -object_type Wire
}
gui_bind_key CTRL+SHIFT+W -cmd sel_shape
proc sel_vias {} {
  set NetName [get_db [dbget selected.] .net.name]
  editSelect -net $NetName  -object_type Via
}
gui_bind_key CTRL+SHIFT+V -cmd sel_vias
proc change_sel_ShapeVia {} {
  set Cellname [dbGet selected.name]
  if {[dbGet selected.objType] == "inst"} { 
    foreach ListNets [dbGet selected.] {
       set ListNetsA [dbGet $ListNets.InstTerms.net.name]
       select_obj $ListNetsA
       deselectInst $Cellname
      # puts $ListNetsA
    }
   } else {
      set NetName [get_db [dbget selected.] .net.name]
      convertNetToSNet -nets $NetName
      editSelect -net $NetName  -object_type Wire
      editSelect -net $NetName  -object_type Via
     } 
}
gui_bind_key CTRL+SHIFT+N -cmd change_sel_ShapeVia
proc get_PinSelection {} {
  dehighlight  
  set Cellname [dbGet selected.name] 
  if {[dbGet selected.objType] == "inst"} {
    foreach ListPins [dbGet selected.] {
       set ListPinsA  [dbget $ListPins.InstTerms.name]
       select_obj $ListPinsA
       foreach ListPinsP [dbget $ListPins.pgInstTerms.name] { 
        set ListPinsPG "$Cellname/$ListPinsP"
        selectObject PGTerm $ListPinsPG
        deselectInst $Cellname
       }
     }
   } else {
      set NetName [get_db [dbget selected.] .net.name]
      set PinName [dbGet [dbGet -p1 top.nets.name $NetName].instTerms.name]
      set lx [get_db [dbGet selected.] .rect.ll.x]
      set ly [get_db [dbGet selected.] .rect.ll.y] 
      set ux [get_db [dbGet selected.] .rect.ur.x]
      set uy [get_db [dbGet selected.] .rect.ur.y]
      set layer [lindex [split [dbGet [dbGet selected.].layer.num] M] end] 
      foreach PinList $PinName {
        select_obj [dbGet top.insts.instTerms.name $PinList]
        select_bump -net $NetName
        deselectWire $lx $ly $ux $uy $layer $NetName
        highlight [dbGet selected.] -index 60
      }
    }
}
gui_bind_key CTRL+SHIFT+P -cmd get_PinSelection
########################################
##############Align shape###############
proc AlignShape {} {
   alignObject -referToFirst -mix -side center
   editMerge
}
gui_bind_key CTRL+SHIFT+A -cmd AlignShape

proc Region {} {
   set coor [eval_common_ui {gui_get_coords}]
   puts "createBusGuide -netGroup DSADC_a-e -centerLine {$coor} -width 40.0000000000  -type hard -layer {1 : 7}"
}  
gui_bind_key F4 -cmd Region
########################################
proc ZTemp {netName} {
  set termPtrList [dbGet [dbGet -p top.nets.name $netName].allTerms]
  foreach term $termPtrList {
    if {[dbGet $term.objType] == "instTerm"} {
      Puts "[dbGet $term.inst.name]"
    }
  }
}
#=========================================
#=========Check_short site row============
#=========================================
proc gcheck_short_row {} {
 foreach bbox [dbget [dbget -p top.fPlan.rows.name *ROW_*].box] {
   set boxlist "{$bbox}"
   select_obj [dbget [dbQuery -areas $boxlist -objType rBlkg]]
 }
}
#############################################
#w.a-start
proc gShow_AnalogNet {} {
set pats [list \
PERI_TOP/PERI_I/isovdd_PBA_TOP/pba_newhier_vertigo_inst/adsvcc_pd/dsadcc* \
PERI_TOP/PERI_I/isovdd_PBA_TOP/pba_newhier_vertigo_inst/afcvcc_pd/IP* 
]
set ofile [open ./dont_route1 w]
foreach pat $pats {
   get_db [get_db nets $pat] -foreach { puts $ofile $obj(.name) }
   }
   close $ofile
   set dont_route_nets "./dont_route1" ;# $env(dont_route_list)
   #w.a-end
}
###################Sel_shape_ObjetcType wire########
proc gsel_shape {} {
  deselectAll
  editSelect -type Regular
}
################################################
#proc userHighlightModule { args } {
#
#  parse_proc_arguments -args $args options
#
#  if { [info exists options(-module)] } {
#  set module_list [list $options(-module)]
#  } else {
#  puts "No module are input"
#  return
#  }
#  set file1 [open module_highlight.tcl w]
#  puts $file1 "dehighlight -all;setPreference HighlightColorNumber 256"
#  set count [llength $module_list]
#  foreach m [split [lindex $module_list 0] " "] {
#    if {$count != 0 && $count < 17 } {
#  puts $file1 "selectModule $m ; highlight -index $count;deselectAll "
#  puts "selectModule $m ; highlight -index $count;deselectAll"
#  puts "$count $m"
#    }
#      incr count
#  }
#  close $file1
#if [file exist "module_highlight.tcl"] {
#source ./module_highlight.tcl
#} else {
#puts "Please check input script"
#}
#}
#
#
#define_proc_arguments [namespace current]::userHighlightModule -info {RVC/HuyTran - Highligh for specificed module} -define_args {
#  {-module "module name" "" list}
#}
#
#userHighlightModule -module "gtm_ip/gtm_core_i/gtm_cls_i_0 gtm_ip/gtm_core_i/gtm_cls_i_1 gtm_ip/gtm_core_i/gtm_cls_i_2 gtm_ip/gtm_core_i/gtm_cls_i_3 gtm_ip/gtm_core_i/gtm_axim_i gtm_ram blk_GTM_LBIST_edt_i gtm_dbg"
###############################
#======Collect Keyfile StarRC=
#=============================
proc get_keyfile_ADC {anet pinname_in} {
  set i 0
  set termPtrList [dbGet [dbGet -p top.nets.name $anet].allTerms]
  foreach pin $termPtrList {
    if {[dbGet $pin.objType] == "instTerm"} {
      set pin_namea "[dbGet $pin.inst.name]"
      set pin_nameb "[dbGet $pin.defName]"
      set prc_net [lindex [split $anet /] end]
      set pin_out "$pin_namea:$pin_nameb"
      if {$pinname_in == $pin_out} {
       } else {
         puts "${prc_net}_0${i}   $prc_net   $pinname_in   $pin_out"
       incr i
      }
    }
  } 
}
#=================================
proc get_keyfile {net} {
  set i 0
  set list_in ""
  set list_out ""
  set list_inout ""
  set termPtrList [dbGet [dbGet -p top.nets.name $net].allTerms]
   foreach pin $termPtrList { 
     if {[dbGet $pin.objType] == "instTerm"} {
      set net_name [lindex [split $net /] end]
      set _direction "[get_db [get_db pins $pin] .direction]" 
      set pin_name "[dbGet $pin.defName]" 
      set cell_full_name "[dbGet $pin.inst.name]"
      if {$_direction == "inout"} {
       lappend list_inout $pin_name $cell_full_name
      } elseif {$_direction == "in"} {
          lappend list_in $pin_name $cell_full_name     
        } elseif {$_direction == "out"} {
           lappend list_out $pin_name $cell_full_name
            }
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
            puts "${net_name}_0${i}   $net   $output_pin   $input_pin"
            incr i
           }
         }
        }
   }
}
###############################
set _var_1 {}
proc zbbox {} {
 if {$::_var_1 == 1} {
   set lpan1 [llength $::bbox]
   if {$::bbox == "0 0"}  {
   remove_gui_marker -all
   zoomBox {0 0.01 0 0}
   add_gui_marker -color "#eeeeee" -name MARKER_Collection -pt {0 0} -type X
   } elseif {$lpan1 == 2 && $lpan1 != "{ }"} {
       remove_gui_marker -all
       add_gui_marker -color "#eeeeee" -name MARKER_Collection -pt $::bbox -type X
     } else {
        deselectAll
        zoomBox $::bbox
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType sWire]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType wire]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType inst]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType rBlkg]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType pBlkg]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType row]]
        select_obj [dbQuery -enclosed_only -areas $::bbox -objType bump]
       }
    }
if {$::_var_1 == 0} {
    set lpan1 [llength $::bbox]
    if {$lpan1 == 2} {
      remove_gui_marker -all
      zoomTo $::bbox
      add_gui_marker -color "#eeeeee" -name MARKER_Collection -pt $::bbox -type X
    }
  } 
return;
}
proc ClearData {} {
    global bbox
        set bbox ""
        remove_gui_marker -all
}
#proc MainZoom {} {
#     set ter .zoomto
#     toplevel $ter -background "#e7e7e7" -width 290 -height 90
#     wm title $ter "Zoom Box"
# 
#     frame $ter.frame
#     label $ter.frame.lab1 -text "Coordinates:" -font "ansi 10 bold"
#     entry $ter.frame.txt -foreground "#161515" -relief ridge -cursor hand2 -exportselection 1 \
#      -font {Helvetica -10 } -width 25 -textvariable bbox -justify left -validate "focusout" \
#      -selectborderwidth 1 -validatecommand {puts $::bbox; return 1}
#     set ::_var_1 1
#     radiobutton $ter.frame.rabut1 -text "Zoom" -variable ::_var_1 -value 1 -font "ansi 10"
#     radiobutton $ter.frame.rabut2 -text "Pan" -variable ::_var_1 -value 0 -font "ansi 10"
# 
#     button $ter.frame.but1 -text "OK" -command {zbbox}
#     button $ter.frame.but2 -text "Cancel" -command {destroy .zoomto}
#     button $ter.frame.but3 -text "Apply" -command {zbbox;destroy .zoomto}
#     button $ter.frame.del -text "X" -background "#ffffff" -foreground "#cc0000" -font "ansi 6 bold" \
#     -height 1 -width 1 -command {ClearData}
# 
#     grid $ter.frame.lab1 -sticky w -row 0 -columnspan 2 -padx 5 -pady 5
#     grid $ter.frame.txt $ter.frame.del -sticky w -row 1 -columnspan 2 -padx 5 -pady 5
#     grid $ter.frame.rabut1 $ter.frame.rabut2 -sticky w -row 2 -columnspan 2 -padx 5 -pady 5
#     grid $ter.frame.but1 $ter.frame.but2 $ter.frame.but3 -sticky w -row 3 -columnspan 2 -padx 5 -pady 5
# 
#     pack $ter.frame -padx 10 -pady 10
#}
#gui_bind_key CTRL+T -cmd MainZoom
proc MainZoom { } {
     set ter .zoomto 
     toplevel $ter -background "#e7e7e7" -width 290 -height 90;
     wm title $ter "Zoom Box"
     label .zoomto.lab1 -text "Coordinates:" -font "ansi 10 bold"
     place .zoomto.lab1  -x 5 -y 35
     entry .zoomto.txt  -foreground "#161515" -relief ridge -cursor hand2 -exportselection 1 \
      -font {Helvetica -10 } -width 25 -textvariable bbox -justify left -validate "focusout" \
      -selectborderwidth 1 -validatecommand {puts $::bbox; return 1} 
     place .zoomto.txt -x 110 -y 35
     set ::_var_1 1
     radiobutton .zoomto.rabut1 -text "Zoom" -variable ::_var_1 -value 1 -font "ansi 10" 
     place .zoomto.rabut1 -x 5 -y 5
     radiobutton .zoomto.rabut2 -text "Pan" -variable ::_var_1 -value 0 -font "ansi 10" 
     place .zoomto.rabut2 -x 100 -y 5
     button .zoomto.but1 -text "OK" -command {zbbox}
     place .zoomto.but1  -x 5 -y 60
     button .zoomto.but2 -text "Cancel" -command { destroy .zoomto }
     place .zoomto.but2  -x 60 -y 60
     button .zoomto.but3 -text "Apply" -command {zbbox;destroy .zoomto}
     place .zoomto.but3  -x 130 -y 60
     button .zoomto.del -text "X" -background "#ffffff" -foreground "#cc0000" -font "ansi 6 bold" \
     -height 1 -width 1 -command {ClearData}
     place .zoomto.del -x 260 -y 32
     pack .zoomto -side top 
     pack .zoomto.rabut1
     pack .zoomto.rabut2
     pack .zoomto.lab1 
     pack .zoomto.txt 
     pack .zoomto.but1 
     pack .zoomto.but2
     pack .zoomto.but3
     pack .zoomto.del
}
gui_bind_key CTRL+T -cmd MainZoom
############################o
proc goutDEFLEF {dir} {
 set product U2B24
 defOut -floorplan -netlist -CutRow -routing $dir/${product}_routing.def
 write_lef_abstract  $dir/${product}.lef 
} 
#############################
proc netlenghth {net} {
    set length 0
    foreach wirePtr [dbGet [dbGet -p top.nets.name $net].sWires] {
     set length [expr $length + [dbget $wirePtr.length]]
    }
  return $length
}
############################
proc c_lBLK {Layer} {
  foreach rblkg [get_db [dbget selected.]] {
             set name [get_db $rblkg .name]
             #set layer [get_db $rblkg .layer.name]
             set llx  [get_db $rblkg .rects.ll.x]
             set lly  [get_db $rblkg .rects.ll.y]
             set urx  [get_db $rblkg .rects.ur.x]
             set ury  [get_db $rblkg .rects.ur.y]
             #set bbox [string trim $box "{}"]
             setSelectedRouteBlk $llx $lly $urx $ury $name $Layer {Undefined ALLNET} {} {}
  }
}
######## Lis_IO_Name########
proc glist_IOName {netName} {
  set termPtrList [dbGet [dbGet -p top.nets.name $netName].allTerms]
  foreach term $termPtrList {
    set listdata [dbGet $term.inst.name]
    set IOList [lsearch -all -inline $listdata IO_TOP*] 
    puts $IOList
  }

} 
######Change_NumberVias##
proc c_NumVias {row columns} {
  editChangeVia -selected -via_columns $columns  -via_rows $row
}
proc mergeRBlkg {RouteBlkgName} {
 set BLkname [dbget selected.name]
 selectRouteBlk $BLkname
 set layerbox [lsort -unique [dbGet selected.layer.name]]
 set polyRouteBlkg [dbShape -output polygon [list [dbGet selected.boxes]]]
 set i 0
 foreach merger_polygon $polyRouteBlkg {
   foreach layer $layerbox {
   createRouteBlk -layer $layer -polygon $merger_polygon -name RB_${RouteBlkgName}_$i
   incr i
  }
deleteRouteBlk -name $BLkname
 }
# foreach RBlkg_name [lsort -unique [dbGet selected.name]] {
#   puts $RBlkg_name
#                deleteRouteBlk -name $RBlkg_name
#                }
}
proc rm_vshape {} {
 set bbox [dbget selected.box]
 deselectAll
 select_obj [dbQuery -enclosed_only -areas $bbox -objType {sViaInst viaInst}]
 deleteSelectedFromFPlan
}
proc cmt_crBLK {} {
  foreach rblkg [dbget selected.] {
             set name [get_db $rblkg .name]
             set llx  [get_db $rblkg .rects.ll.x]
             set lly  [get_db $rblkg .rects.ll.y]
             set urx  [get_db $rblkg .rects.ur.x]
             set ury  [get_db $rblkg .rects.ur.y]
             puts "createRouteBlk -name $name -layer metal1 -box {$llx $lly $urx $ury} -exceptpgnet" 
 }
}
#verify_PG_short -net $Analog_net -no_routing_blkg
#verifyConnectivity -net $Analog_net -noAntenna -noFloatingMetal -noSoftPGConnect
set restore_db_file_check 0
setCheckMode -tapeOut 0
#################### PNR command #######################
proc zplace_IOPin {name from to position layer xy} { 
 set coordi [regsub -all {\{|\}} $xy ""] 
 if {($position=="Right") || ($position=="Top")} {
  if {$to == 0} {
    editPin -pinWidth 0.05 -pinDepth 0.28 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side $position -layer $layer -spreadType start -spacing 0.24 -start $coordi -pin \{$name[0]\}
  } else {
     for {set i $from} {$i <= $to} {incr i} {
      set SelPin [selectPin $name[$i]]
      set pinName [dbget selected.name]
      set PinNamefix [regsub -all {\{|\}} $pinName ""]
      set PinNamesort [lsort -dictionary $PinNamefix] 
    }
      editPin -pinWidth 0.05 -pinDepth 0.28 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side $position -layer $layer -spreadType start -spacing 0.24 -start $coordi -pin $PinNamesort
      deselectAll
  }
 }
 if {$position=="Left"} {
  if {$to == 0} {
   editPin -pinWidth 0.05 -pinDepth 0.28 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side $position -layer $layer -spreadType start -spacing 0.24 -start $coordi -pin \{$name[0]\}
 } else {
    for {set i $from} {$i <= $to} {incr i} {
     set SelPin [selectPin $name[$i]]
     set pinName [dbget selected.name]
     set PinNamefix [regsub -all {\{|\}} $pinName ""]
     set PinNamesort [lsort -dictionary $PinNamefix]
    }
     editPin -pinWidth 0.05 -pinDepth 0.28 -fixedPin 1 -fixOverlap 1 -unit MICRON -spreadDirection clockwise -side $position -layer $layer -spreadType start -spacing 0.24 -start $coordi -pin $PinNamesort
     deselectAll
  }
 }
puts "garrange_IOPin <abc> <2> <10> <Left Right Top...> <M1 M2...> <{lx ly rx ry}> "
}
#########Collect_Errors##################
#proc Collec_error_cell {} {
# set input [open "./" r]
# set match 0
# while {![eof $input]} {
#     set line [gets $input]
#     if {$match == 1} {
# 	if {[regexp {.+M3.+Bounds\s(.+)} $line full_match box]} {
# 	    set bbox "\{[regsub -all {,} $box ""]\}"
#             puts $bbox
#             select_obj [dbget [dbQuery -enclosed_only -areas $bbox -objType inst]]
#             highlight [dbGet selected.] -index 28
#         }
#         set match 0
#     }
#     if {[regexp {.+Metal\sShort.*} $line fullmatch]} {
#         set match 1
#     }
# }
# close $input
#}
#######Make area congestion#############
proc Maker_Congestion {inputfile {gets stdin}} {
  set datastr  [llength [split $inputfile ""]]
  if {($datastr < 20)||($datastr == 0x0)} { 
    puts  "\033\[1;31mUsage:          Maker_Congestion <data of Congestion>\033\[0m"
    puts  "\033\[1;31mEx:  Maker_Congestion ../../Congestion.05.rpt\033\[0m"
} else {
   clearDrc 
   set f [open $inputfile]
   set data [read $f]
   close $f
   if {[regexp {.+( 1)\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)\s+\S+\s+(\S+)} $data -> num1 congestion1 score1]} {
      if {($score1 >= 0) && ($score1 <= 200)} {
        createMarker -bbox $congestion1 -desc "congested of value: $score1 <=200--> OK | It's routable" -tool "Congestion(1)"  
      } elseif {($score1 >= 200) && ($score1 < 500)} {
          createMarker -bbox $congestion1 -desc "congested of value: 200 < $score1 < 500--> NG | It's risky to route" -tool "Congestion(1)" 
       } else {
        createMarker -bbox $congestion1 -desc "congested of value: $score1 > 500--> Critical | It may not routable." -tool "Congestion(1)"
       }
   }
   if {[regexp {.+( 2)\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)\s+\S+\s+(\S+)} $data -> num2 congestion2 score2]} {
      if {($score2 >= 0) && ($score2 <= 200)} {
        createMarker -bbox $congestion2 -desc "congested of value: $score2 <=200--> OK | It's routable" -tool "Congestion(2)"
      } elseif {($score2 >= 200) && ($score2 < 500)} {
          createMarker -bbox $congestion2 -desc "congested of value: 200 < $score2 < 500--> NG | It's risky to route" -tool "Congestion(2)" 
       } else {
        createMarker -bbox $congestion2 -desc "congested of value: $score2 > 500--> Critical | It may not routable." -tool "Congestion(2)"
       }   
   }
   if {[regexp {.+( 3)\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)\s+\S+\s+(\S+)} $data -> num3 congestion3 score3]} {
      if {($score3 >= 0) && ($score3 <= 200)} {
        createMarker -bbox $congestion3 -desc "congested of value: $score3 <=200--> OK | It's routable" -tool "Congestion(3)"
      } elseif {($score3 >= 200) && ($score3 < 500)} {
          createMarker -bbox $congestion3 -desc "congested of value: 200 < $score3 < 500--> NG | It's risky to route" -tool "Congestion(3)"
       } else {
        createMarker -bbox $congestion3 -desc "congested of value: $score3 > 500--> Critical | It may not routable." -tool "Congestion(3)"
       }
   }
   if {[regexp {.+( 4)\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)\s+\S+\s+(\S+)} $data -> num4 congestion4 score4]} {
      if {($score4 >= 0) && ($score4 <= 200)} {
        createMarker -bbox $congestion4 -desc "congested of value: $score4 <=200--> OK | It's routable" -tool "Congestion(4)"
      } elseif {($score4 >= 200) && ($score4 < 500)} {
          createMarker -bbox $congestion4 -desc "congested of value: 200 < $score4 < 500--> NG | It's risky to route" -tool "Congestion(4)"
       } else {
        createMarker -bbox $congestion4 -desc "congested of value: $score4 > 500--> Critical | It may not routable." -tool "Congestion(4)"
       }
   }
   if {[regexp {.+( 5)\s+\S+\s+(\S+\s+\S+\s+\S+\s+\S+)\s+\S+\s+(\S+)} $data -> num5 congestion5 score5]} {
      if {($score5 >= 0) && ($score5 <= 200)} {
        createMarker -bbox $congestion5 -desc "congested of value: $score5 <=200--> OK | It's routable" -tool "Congestion(5)"
      } elseif {($score5 >= 200) && ($score5 < 500)} {
          createMarker -bbox $congestion5 -desc "congested of value: 200 < $score5 < 500--> NG | It's risky to route" -tool "Congestion(5)"
       } else {
        createMarker -bbox $congestion5 -desc "congested of value: $score5 > 500--> Critical | It may not routable." -tool "Congestion(5)"
       }
   }
 }
}
##############################################
proc rp_Timing {from to mode} {
 if {$mode == "setup"} {
  report_timing -from $from -to $to -machine_readable > ./05_in2reg_setup.rpt
 } elseif {$mode == "hold"} {
  report_timing -from $from -to $to -view view_func_bcgh_rcmax_${mode} -early -machine_readable > ./05_in2reg_hold.rpt
 } else {
 }
}
#############################################
proc DRC_check {} {
 clearDrc
 checkPlace
 verifyConnectivity -type all -noAntenna -noWeakConnect -noSoftPGConnect -error -1 -warning 50
 verify_drc -limit -1
}
########remove Pin########################
proc remove_IoPin {} {
 set designName [lindex [dbget head.allCells.name] 0]
 set unplaced_pins [dbGet selected.name]
 set ptngSprNoRefreshPins 1
 setPtnPinStatus -cell $designName -pin $unplaced_pins -status unplaced -silent
 set ptngSprNoRefreshPins 0
 ptnSprRefreshPinsAndBlockages
}
################gen_BLK#############
proc gen_dataBLkVer4 {dir} {
 deselectAll
 set timeline [clock format [clock seconds] -format %y%m%d]
 selectRouteBlk *
 set name_blk [lindex [dbget selected.name] 0]
 writeFPlanScript -selected -fileName $dir/${name_blk}_${timeline}.tcl_toINN
 puts "\033\[2;32mCreated data:\033\[1;34m${name_blk}_${timeline}.tcl_toINN\033\[1;32m Successfully\033\[0m"
}
############Gen_IOPIN############
proc genIOPin {fileName} {
  selectIOPin *
  writeFPlanScript -sections pins -fileName ${fileName}.tcl
}
##############Load ERROR DRC LVS##############
proc loadCalibre {dir} {
   loadViolationReport -type Calibre -filename $dir
}
############### FIX nonCLKcell&VT#############
proc gfix_nClkVtCell {inputfile} {
 set in [open $inputfile] 
 set match 1
 while {![eof $in]} {
   set line [gets $in]
   if {$match == 1} { 
    if {[regexp {\s+B*\s+(\S+)\s+(\S+)} $line full_match oldBUF Intan]} {
       #set temp [lindex $oldBUF -2]
       puts $Intan
      # puts "ecoChangeCell -inst $Intan -cell BUFPERMX8A"
    }
   }
 }
 close $in
}
############ FIX Glit #######################
proc gfix_glit {inputdir} {
 puts "Input Buffer: "
 set cellName [gets stdin]
 set outf [open "NetGlit.rpt" w]
 foreach glitFile [glob $inputdir/*/glitch.rpt] {
   set global_data [open $glitFile "r"]
   set match 1
   while {![eof $global_data]} {
     set global_line [gets $global_data]
     if {$match == 1} {
       if {[regexp {.*\((.*)\)\s+(\S+)} $global_line full_match prcesstring1]} {
         if {$prcesstring1 in $prcesstring1} {
            puts $outf "$prcesstring1"
         }
       }
     }
   }    
 } 
 close $outf
  set read_file [open "NetGlit.rpt"]
  set checkdata [read $read_file] 
  close $read_file 
  set unique_string [string map {{"\n" ""} {"\r" ""}} $checkdata]
  set lines_file [split $unique_string "\n"]
  set sorted_uniques [lsort -unique $lines_file]
  foreach pNets $sorted_uniques {
   if {$pNets eq ""} {
      continue
   } 
   set Nets $pNets
   set updateTiming [getEcoMode -updateTiming -quiet]
   set refinePlace [getEcoMode -refinePlace -quiet]
   set honorDontUse [getEcoMode -honorDontUse -quiet]
   setEcoMode -updateTiming false -refinePlace false -honorDontUse false
   setEcoMode -batchMode true
   ecoAddRepeater -cell $cellName -net $Nets -relativeDistToSink 0.5
   setEcoMode -batchMode false
   setEcoMode -updateTiming $updateTiming -refinePlace $refinePlace -honorDontUse $honorDontUse    
} 
file delete "NetGlit.rpt"
} 
####################FIX_DRV###################
proc gfix_DRV {inputdir} {
 foreach DRVFile [glob $inputdir/*VW*CMAX*_rpts/drc_slewChkData.rpt] { 
     set global_data [open $DRVFile "r"] 
     set match 1
     while {![eof $global_data]} {
        set global_line [gets $global_data] 
        if {$match == 1} {
         if {[regexp {\s+(\S+)\s+(\S+).+\((VIOLATED\))} $global_line full_match prcesstring1]} {
           #set foo [$prcesstring1]
           puts $prcesstring1
             
         }
        }
     }
 }
}


#############################################
proc addSramM4RoutingBlkg {} {      
        set list_layerRouteBlk [list  M4 ]
        set uncnt 0                 
        set cnt 0                   
        foreach_in_collection inst [filter_collection [all_registers -macros] "is_memory_cell == true"] {
                set instPtr [get_attribute $inst full_name]
                set ori [dbGet [dbGet top.insts.name $instPtr -p].orient]
                if { $ori == "R0" || $ori == "MX" || $ori == "R180" || $ori == "MY"} {                                                                                                                                                                                                                                                                        
                        set x [dbGet [dbGet top.insts.name $instPtr -p].box_llx]
                        set x1 [expr $x + 0]
                        set x2 [expr $x + 0.85]
                        set y1 [dbGet [dbGet top.insts.name $instPtr -p].box_lly]
                        set y2 [dbGet [dbGet top.insts.name $instPtr -p].box_ury]
                        createRouteBlk -exceptpgnet -layer  $list_layerRouteBlk -name addSramM4RoutingBlkg  -box  $x1 $y1 $x2 $y2
                        set x [dbGet [dbGet top.insts.name $instPtr -p].box_urx]
                        set x1 [expr $x - 0]           
                        set x2 [expr $x - 0.85]           
                        set y1 [dbGet [dbGet top.insts.name $instPtr -p].box_lly]
                        set y2 [dbGet [dbGet top.insts.name $instPtr -p].box_ury]
                        createRouteBlk -exceptpgnet -layer  $list_layerRouteBlk  -name addSramM4RoutingBlkg  -box  $x1 $y1 $x2 $y2

                        incr cnt    
                } elseif  {$ori == "R0" || $ori == "MX" || $ori == "R180" || $ori == "MY"} {
                        set x [dbGet [dbGet top.insts.name $instPtr -p].box_urx]
                        set x1 [expr $x - 0]
                        set x2 [expr $x - 0.35]
                        set y1 [dbGet [dbGet top.insts.name $instPtr -p].box_lly]
                        set y2 [dbGet [dbGet top.insts.name $instPtr -p].box_ury]
                        createRouteBlk -exceptpgnet -layer  $list_layerRouteBlk  -name addSramM4RoutingBlkg  -box  $x1 $y1 $x2 $y2
                        set x [dbGet [dbGet top.insts.name $instPtr -p].box_llx]
                        set x1 [expr $x + 0]    
                        set x2 [expr $x + 0.85]    
                        set y1 [dbGet [dbGet top.insts.name $instPtr -p].box_lly]
                        set y2 [dbGet [dbGet top.insts.name $instPtr -p].box_ury]
                        createRouteBlk -exceptpgnet -layer  $list_layerRouteBlk -name addSramM4RoutingBlkg  -box  $x1 $y1 $x2 $y2
                        incr cnt    
                } else {            
                        puts "Can not create a RoutingBlg for $instPtr. Please check the orient of this inst! ^ ^ "
                        incr uncnt  
                }                   
                                    
    }                               
  Puts ""                           
  Puts "Done !! totally create $cnt  Routing blockage for SRAM and $uncnt SRAM can not create."
  Puts "  You can remove these routing blockage by this command:"
  Puts "    deleteRouteBlk -name addSramM4RoutingBlkg"
  Puts ""                           
}           
###########change_via_type##############
proc gchange_ViaType {new_via} {
  set old_via [dbget selected.via.name]
tormQA.rpt deselectAll
  editSelectVia -via_cell $old_via
  editChangeVia -selected -from $old_via -to $new_via
}
###########################################
##########GenNetlist######################

###################change_cell_name########
proc ChangName {$bug $change} {
 update_name -restricted {$bug} -replace_str $change
}
############### gen pgcell.map############
proc printPGCellMap { lef} {             
                                         
  global soce_lib                        
  global LIB                             
                                         
  if {$lef == ""} {                      
     putWarn "\[$LIB\] (printPGCellMap) lef_io.lef Path is \"\""  
     return 0                            
  }                                      
  if {![file exists $lef]} {             
     putInfo "\[$LIB\] Debug io lef: $lef"
     if {[lindex $LIB 1]=="O"} {         
        putError "\[$LIB\] (printPGCellMap) $lef is not found"  
     } else {                            
        putWarn "\[$LIB\] (printPGCellMap) bypass printing pgcell.map..."  
          }                              
     return -1                           
                                         
  }                                      
                                         
  putInfo "\[$LIB\] CREATE pgcell.map"   
  set fp [open "$soce_lib/pgcell.map" "w"]
                                    
  catch {exec grep MACRO $lef | grep VCC} vccList
  catch {exec grep MACRO $lef | grep GND} gndList
  catch {exec grep MACRO $lef | grep GPCUT} gpcutList
  catch {exec grep MACRO $lef | grep LCUT} lcutList
  catch {exec grep MACRO $lef | grep RCUT} rcutList
  catch {exec grep MACRO $lef | grep EMPTYGR} emptygrList
                                    
  set virtualList [concat $gpcutList $emptygrList $lcutList $rcutList]
                                    
  set vccTypeList [list]            
  set gndTypeList [list]            
  set virtualTypeList [list]        
                                    
  set libKey [string range $LIB 0 3]
                                    
  foreach cell $virtualList {       
       set leng [string length $cell]   
       set pinText ""               
       set pinText1 ""              
       set pinText2 ""              
       set pinText3 ""              
       set pinText4 ""              
                                    
       regexp {GPCUT} $cell pinText1
       regexp {EMPTYGR} $cell pinText2  
       regexp {RCUT[0-9]*} $cell pinText3
       regexp {LCUT[0-9]*} $cell pinText4
                                    
       if {$pinText1!=""} { set pinText $pinText1 }
       if {$pinText2!=""} { set pinText $pinText2 }
       if {$pinText3!=""} { set pinText $pinText3 }
       if {$pinText4!=""} { set pinText $pinText4 }
                                    
       if {$pinText==""} { continue }
                               
       set padText "NOPAD:"    
                               
       ##--- exception  ---##  
       if {$LIB=="FOC0H_R33"} {
          set pinText $cell    
       }                       
                               
       set pgLine  [format "%-10s\t%-10s\t%-10s\t%-10s\tV" $pinText $LIB $cell $padText]
                               
       set leng1 [expr $leng-1] 
       set type [string rang $cell $leng1 $leng]
                               
       if {![info exists pgTypeList(VIRTUAL,$type)]} {
          set pgTypeList(VIRTUAL,$type) [list]
          lappend virtualTypeList $type
       }                        
       lappend pgTypeList(VIRTUAL,$type) $pgLine
  }                            
                               
  foreach cell $vccList {       
    if {$cell != "MACRO" && ![regexp {_} $cell] && [regexp {^VCC} $cell]} {
       set pinText ""          
       set padText ""           
       set leng [string length $cell]
                               
       regexp {VCC[0-9]*[IOKAB]+} $cell pinText
       regexp {VCC[0-9]*[A]?} $cell padText
                               
       if {$pinText==""} { continue }
                               
       if {[regexp {CUT} $cell]} {  
          set pinText "${pinText}CUT"
       }                       
                                
       set processVoltList [list]
       switch -regexp $libKey {                                                          
        "70"  { lappend processVoltList "VCC5" } 
        "80"  { lappend processVoltList "VCC3" } 
        "90"  { lappend processVoltList "VCC2" } 
        "A0"      
        - "B0"    
        - "P0"            
              { lappend processVoltList "VCC18" } 
        "C0"      
        - "R0"            
              { lappend processVoltList "VCC12" }
        "D0"      
        - "E0"    
        - "F0"            
              { lappend processVoltList "VCC2" 
                lappend processVoltList "VCC15"
              }           
        default { putError "$libKey is not found for pgcell" }
       }
       
       if {$padText=="VCC" || [lsearch -exact $processVoltList $padText]!=-1} {
          set padText "VCC:"  
       } else {           
          if {[regexp A $padText]} { 
             set padText "${padText}:"
          } else {        
             set padText "${padText}V:"
          }
       }
       
       ##--- exception  ---## 
       if {$LIB=="FOC0H_R33"} {
          set pinText $cell
       }
                                              
       set pgLine  [format "%-10s\t%-10s\t%-10s\t%-10s\tC" $pinText $LIB $cell $padText]
                                              
       set leng1 [expr $leng-1]
       set type [string rang $cell $leng1 $leng]
                              
       if {![info exists pgTypeList(VCC,$type)]} {
          set pgTypeList(VCC,$type) [list]    
          lappend vccTypeList $type           
       }                      
       lappend pgTypeList(VCC,$type) $pgLine
    }                         
  }                        
                           
  foreach cell $gndList {  
    if {$cell != "MACRO" && ![regexp {_} $cell] && [regexp {^GND} $cell]} {
       set pinText ""      
       set leng [string length $cell]         
                           
       regexp {GND[0-9]*[IOKAB]+} $cell pinText
       regexp {GND[0-9]*[A]?} $cell padText   
                           
       if {$pinText==""} { continue }         
                           
       if {[regexp {CUT} $cell]} {            
          set pinText "${pinText}CUT"         
       }                   
                           
       set padText "GND:"  
                           
       ##--- exception  ---##
       if {$LIB=="FOC0H_R33"} {               
          set pinText $cell 
       }                   
                                       
       set pgLine  [format "%-10s\t%-10s\t%-10s\t%-10s\tC" $pinText $LIB $cell $padText]
                                       
       set leng1 [expr $leng-1]               
       set type [string rang $cell $leng1 $leng]
                                       
       if {![info exists pgTypeList(GND,$type)]} {
          set pgTypeList(GND,$type) [list]    
          lappend gndTypeList $type           
       }                               
       lappend pgTypeList(GND,$type) $pgLine
                                       
       ##--- exception  ---##                 
       if {$LIB=="FOC0H_A33" || $LIB=="FOC0H_O33"} {
          if {[regexp {GND3} $pinText]} {     
             regsub {GND3} $pinText {GND2} pinText_new
             set pgLine  [format "%-10s\t%-10s\t%-10s\t%-10s\tC" $pinText_new $LIB $cell $padText]
             lappend pgTypeList(GND,$type) $pgLine
          }                            
       }                               
    }                                  
  }                                    
                                              
   
  puts $fp  "#-------------------------------------------------------------------"
  puts $fp  "# comment character \"#\"" 
  puts $fp  "# Note: Don't add leading delimeter at pinName"
  puts $fp  "#                                       V : no extra device"
  puts $fp  "#                                       C : with extra device"
  puts $fp  "# pin    library  cellname     text_label     device"
  puts $fp  "#"    
  foreach type $virtualTypeList {       
    puts $fp "#-------------------------------------------------------------------"
    puts $fp "# Virtual Type $type"     
    puts $fp "#-------------------------------------------------------------------"
    foreach line $pgTypeList(VIRTUAL,$type) {
      puts $fp $line           
    }
   
  }
   
  foreach type $vccTypeList {           
    puts $fp "#-------------------------------------------------------------------"
    puts $fp "# VCC Type $type"         
    puts $fp "#-------------------------------------------------------------------"
    foreach line $pgTypeList(VCC,$type) {
      puts $fp $line           
    }
  }
            
  foreach type $gndTypeList {       
    puts $fp "#-------------------------------------------------------------------"
    puts $fp "# GND Type $type"     
    puts $fp "#-------------------------------------------------------------------"
    foreach line $pgTypeList(GND,$type) {
      puts $fp $line
    }       
  }         
            
            
  close $fp 
}           
############################
#############cr_BLK on Intance#####
proc cr_BLKIntance {} {
 set inst [dbGet selected]
 set x0 [dbGet $inst.box_llx]
 set x1 [dbGet $inst.box_urx]
 set y0 [dbGet $inst.box_lly]
 set y1 [dbGet $inst.box_ury]
 set area "$x0 $y0 $x1 $y1"
 createRouteBlk -box $area -layer {1 2 3 4 5 6 7 8 9} -name ESD_BLK
}
###########globle connect###
proc genGloble_connect {net pin} {
 foreach data [dbget selected.name] {
 puts "globalNetConnect $net -type pgpin -pin $pin -inst $data -override -verbose"
 }
}
#####FIX_ANTENA########
proc gfix_ANTENA {cell} {
file delete "natAntenna.tcl"
verifyProcessAntenna -reportfile ANTENNA_ERROR.rpt -error 1000
violationBrowserReport -report ANTENNA_ERROR.rpt -process_antenna
deselectAll
set globVar ""
set globVar_1 ""
set fh [open "ANTENNA_ERROR.rpt" r]
 while {[gets $fh line] >= 0} {
   if {[regexp {/} $line]} {
     set prcNet [regsub -all {Pin of Net } $line ""]
     regsub -all {[\r\n]+} $prcNet " " string
     set stringable "$prcNet "
     set globVar [append globVar $stringable]
   }                
   if {[regexp {.+Bounds\s+(\S+\s+\S+)} $line -> bbox]} {
        set bboxpra [regsub -all {\