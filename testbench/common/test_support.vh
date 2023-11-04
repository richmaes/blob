logic[63:0] error_count = 0;
logic[63:0] lcl_error_count = 0;
logic bool_quick_mode = 0;
logic[511:0] support_test_passes;
logic[15:0] support_test_fails [0:511];
logic[511:0] support_test_was_run;
task test_init;
error_count = 0;     
lcl_error_count = 0; 
endtask

task display_test_begin_status;
    begin 
        
        `ifdef QUICK_MODE
        bool_quick_mode = 1;
        `endif

        $display("=========================================================================");
        $display("| Test: %s    QUICK_MODE = %s", `TEST_NAME_STR, bool_quick_mode ? "ON" : "OFF");
        $display("| VERBOSE = %0d", `VERBOSE);
        $display("=========================================================================");
    end
endtask

task display_test_start;
    input[31:0] test_id;
    input string test_description;

    begin
        lcl_error_count = 0;
        $display("=========================================================================");
        $display("%0t: Test %0d : %s.", $time, test_id, test_description);
        $display("=========================================================================");
    end
endtask

task display_test_end;
    input[31:0] test_id;
    begin
        $display("=========================================================================");
        $display("%0t: Test %0d Complete with %0d ERRORS.", $time, test_id, lcl_error_count);
        $display("=========================================================================");
        support_test_was_run[test_id] = 1'b1;
        if (lcl_error_count == 0) 
            support_test_passes[test_id] = 1'b1;
        else
            support_test_fails[test_id] = lcl_error_count;
    end
endtask

task display_error_inc;
    input string error_description;
    begin
       error_count++;
       lcl_error_count++;
       //$display("=========================================================================");
       $display("%0t: ERROR:  %s : error_count: %0d",$time, error_description, error_count );
       //$display("=========================================================================");
       `ifdef TEST_STOP_ON_ERROR
        if (error_count >= `TEST_STOP_ON_ERROR_LIMIT) begin
            $display("%0t, Stopping on error count = %d, %m", $time, error_count); 
            $finish();
        end
       `endif
    end
endtask

task display_test_final_status;
    //input string testname;
    begin
       $display("=========================================================================");
       $display("%0t: Test %s %s with %0d ERRORS",$time, `TEST_NAME_STR, error_count > 0 ? "FAILS" : "PASSES",error_count);
       $display("=========================================================================");
       if (error_count !== 'h0)
           begin
              $display("Test failures:");
              for (int err_fail_cnt = 0;err_fail_cnt < 512; err_fail_cnt = err_fail_cnt + 1)
                  begin
                      if (support_test_was_run[err_fail_cnt] == 1'b1 && support_test_passes[err_fail_cnt] != 1'b1)
                          begin
                             $display("Test %d, fails with %d errors", err_fail_cnt, support_test_fails[err_fail_cnt]);
                          end
                  end
           end
    end
endtask

task display_no_test_found;
	input[31:0] test_id;
    input string test_description;

    begin
        lcl_error_count = 0;
        $display("=========================================================================");
        $display("%0t: Test %0d : %s NOT FOUND SKIPPING.", $time, test_id, test_description);
        $display("=========================================================================");
    end
endtask
