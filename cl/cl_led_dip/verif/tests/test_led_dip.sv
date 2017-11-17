module test_led_dip();

	import tb_type_defines_pkg::*;

	logic [15:0] vdip_value;
	logic [15:0] vled_value;

	initial begin
		
		tb.power_up();

		// set vDIP to 0x0000.
      	tb.set_virtual_dip_switch(.dip(16'h0000));
		vdip_value = tb.get_virtual_dip_switch();
		$display("[%t] vdip = 0x%x", $realtime, vdip_value);
	
		vled_value = tb.get_virtual_led();
		$display("[%t] vled = 0x%x", $realtime, vled_value);	

		// set vDIP to 0xbeef.
		tb.set_virtual_dip_switch(.dip(16'hbeef));
		vdip_value = tb.get_virtual_dip_switch();
		$display("[%t] vdip = 0x%x", $realtime, vdip_value);
		#10ns; // wait 10ns
	
		vled_value = tb.get_virtual_led();
		$display("[%t] vled = 0x%x", $realtime, vled_value);

		if (vled_value == 16'hfeeb)
			$display("[%t] Test passed.", $realtime);
		else
			$display("[%t] Test failed.", $realtime);

	   	tb.kernel_reset();
     	tb.power_down();
      
     	$finish;
   end
endmodule
