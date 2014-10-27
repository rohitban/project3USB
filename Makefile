CC=vcs

FLAGS=-sverilog -debug -assert filter -assert enable_diag

#default: simple
#default: full
default: faulty

#student: top.sv usbBusAnalyzer.svp tb.sv usbHost.sv thumb.sv.e 
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp tb.sv usbHost.sv thumb.sv.e
#student: top.sv usbBusAnalyzer.svp tb.sv usbHost.sv thumb.sv.e bs_encoder.sv crc5_sd.sv crc_new.sv dpdm.sv nrzi.sv lib.sv protocolFSM.sv bs_decoder.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv rwFSM.sv crc16.sv 
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp tb.sv usbHost.sv thumb.sv.e bs_encoder.sv crc5_sd.sv crc_new.sv dpdm.sv nrzi.sv lib.sv protocolFSM.sv bs_decoder.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv rwFSM.sv crc16.sv 

#simple: top.sv usbBusAnalyzer.svp TA_tb_simple.svp usbHost.sv thumb.sv.e lib.sv bs_encoder.sv crc5_sd.sv crc16.sv crc_new.sv dpdm.sv nrzi.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv bs_decoder.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv protocolFSM.sv rwFSM.sv  
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp TA_tb_simple.svp usbHost.sv thumb.sv.e lib.sv bs_encoder.sv crc5_sd.sv crc16.sv crc_new.sv dpdm.sv nrzi.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv bs_decoder.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv protocolFSM.sv rwFSM.sv


faulty: top.sv usbBusAnalyzer.svp TA_tb_faults.svp usbHost.sv thumb_faulty.sv.e lib.sv bs_encoder.sv crc5_sd.sv crc16.sv crc_new.sv dpdm.sv nrzi.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv bs_decoder.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv protocolFSM.sv rwFSM.sv  
	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp TA_tb_faults.svp usbHost.sv thumb_faulty.sv.e lib.sv bs_encoder.sv crc5_sd.sv crc16.sv crc_new.sv dpdm.sv nrzi.sv bitstuffer.sv bitUnstuffer.sv pid_checker.sv bs_decoder.sv decode_nrzi.sv rc_crc16.sv rc_crc.sv rc_dpdm.sv protocolFSM.sv rwFSM.sv

#full: top.sv usbBusAnalyzer.svp TA_tb_full.svp usbHost.sv thumb.sv.e
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp TA_tb_full.svp usbHost.sv thumb.sv.e

#faulty: top.sv usbBusAnalyzer.svp TA_tb_faults.svp usbHost.sv thumb_faulty.sv.e
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp TA_tb_faults.svp usbHost.sv thumb_faulty.sv.e

#prelab: top.sv usbBusAnalyzer.svp prelab_tb.svp usbHost.sv prelab_thumb.sv.e
#	$(CC) $(FLAGS) top.sv usbBusAnalyzer.svp prelab_tb.svp usbHost.sv prelab_thumb.sv.e

clean:
	rm -rf simv
	rm -rf simv.daidir
	rm -rf csrc
	rm -rf ucli.key
	rm -rf simv.vdb
	rm -rf DVEfiles
	rm -rf inter.vpd

