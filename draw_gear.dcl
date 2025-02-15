draw_gear: dialog {
	   label = "Gear Drawing Routine";
	   : column {
	   : boxed_radio_column {
	   label = "Type";

	   : radio_button {
	   key = "rb1";
	   label = "Spur";
	   value = "1";
	   }

	   : radio_button {
	   key = "rb2";
	   label = "Helical";
	   }
	   : radio_button {
	   key = "rb3";
	   label = "Straight Bevel";
	   }
	   : radio_button {
	   key = "rb4";
	   label = "Arc? Spiral Bevel";
	   }
	   : radio_button {
	   key = "rb5";
	   label = "Zerol? (Experimental)";
	   }
	   }

	   //ok_cancel;

	   : boxed_column {
	     : edit_box {
	       key = "module";
	       label = "Module";
	       edit_width = 10;
	       value = "3";
	       initial_focus = true;
	       }
	     : edit_box {
	       key = "numt";
	       label = "Num. of teeth";
	       edit_width = 10;
	       value = "20";
	       }
	     : edit_box {
	       key = "pressure_angle";
	       label = "Pressure angle";
	       edit_width = 10;
	       value = "20";
	       }
	     : edit_box {
	       key = "fillet_r";
	       label = "Fillet radius";
	       edit_width = 10;
	       value = "0.5";
	       }  
	     : edit_box {
	       key = "step";
	       label = "Involute accuracy";
	       edit_width = 10;
	       value = "20";
	       }
	     : edit_box {
	       key = "height";
	       label = "Height";
	       edit_width = 10;
	       value = "30";
	       }
	     : edit_box {
	       key = "pitch_angle";
	       label = "Pitch angle";
	       edit_width = 10;
	       value = "45";
	       }
	     : edit_box {
	       key = "helix_angle";
	       label = "Helix angle/Spiral angle";
	       edit_width = 10;
	       value = "35";
	       }
	   }
	   }
	   : boxed_row {
	          : button {
	            key = "accept";
	            label = " Okay ";
	            is_default = true;
	          }
	          : button {
	            key = "cancel";
	            label = " Cancel ";
	            is_default = false;
	            is_cancel = true;
	          }
	        }
	        }