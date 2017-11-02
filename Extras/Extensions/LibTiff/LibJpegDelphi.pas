unit LibJpegDelphi;

interface

uses
  SysUtils;

const

  {$ifndef FPC}
  JPEG_LIB_VERSION = 62;    { Version 6b }
  {$else}
  JPEG_LIB_VERSION = 80;    { Version 80 }
  {$endif}

  JMSG_STR_PARM_MAX = 80;
  JMSG_LENGTH_MAX = 200;    { recommended size of format_message buffer }
  NUM_QUANT_TBLS = 4;       { Quantization tables are numbered 0..3 }
  NUM_HUFF_TBLS = 4;        { Huffman tables are numbered 0..3 }
  NUM_ARITH_TBLS = 16;      { Arith-coding tables are numbered 0..15 }
  MAX_COMPS_IN_SCAN = 4;    { JPEG limit on # of components in one scan }
  C_MAX_BLOCKS_IN_MCU = 10; { compressor's limit on blocks per MCU }
  D_MAX_BLOCKS_IN_MCU = 10; { decompressor's limit on blocks per MCU }
  DCTSIZE2 = 64;

  JCS_UNKNOWN = 0;          { error/unspecified }
  JCS_GRAYSCALE = 1;        { monochrome }
  JCS_RGB = 2;              { red/green/blue }
  JCS_YCbCr = 3;            { Y/Cb/Cr (also known as YUV) }
  JCS_CMYK = 4;             { C/M/Y/K }
  JCS_YCCK = 5;             { Y/Cb/Cr/K }

type

  PRJpegErrorMgr = ^RJpegErrorMgr;
  PRJpegMemoryMgr = Pointer;
  PRJpegProgressMgr = Pointer;
  PRJpegDestinationMgr = ^RJpegDestinationMgr;
  PRJpegSourceMgr = ^RJpegSourceMgr;
  PRJpegComponentInfo = ^RJpegComponentInfo;
  PRJpegQuantTbl = Pointer;
  PRJpegHuffTbl = Pointer;
  PRJpegScanInfo = Pointer;
  PRJpegCompMaster = Pointer;
  PRJpegCMainController = Pointer;
  PRJpegCPrepController = Pointer;
  PRJpegCCoefController = Pointer;
  PRJpegMarkerWriter = Pointer;
  PRJpegColorConverter = Pointer;
  PRJpegDownsampler = Pointer;
  PRJpegForwardDct = Pointer;
  PRJpegEntropyEncoder = Pointer;
  PRJpegSavedMarker = Pointer;
  PRJpegDecompMaster = Pointer;
  PRJpegDMainController = Pointer;
  PRJpegDCoefController = Pointer;
  PRJpegDPosController = Pointer;
  PRJpegInputController = Pointer;
  PRJpegMarkerReader = Pointer;
  PRJpegEntropyDecoder = Pointer;
  PRJpegInverseDct = Pointer;
  PRJpegUpsampler = Pointer;
  PRJpegColorDeconverter = Pointer;
  PRJpegColorQuantizer = Pointer;
  PRJpegCommonStruct = ^RJpegCommonStruct;
  PRJpegCompressStruct = ^RJpegCompressStruct;
  PRJpegDecompressStruct = ^RJpegDecompressStruct;

  TJpegErrorExit = procedure(cinfo: PRJpegCommonStruct); cdecl;
  TJpegEmitMessage = procedure(cinfo: PRJpegCommonStruct; MsgLevel: Integer); cdecl;
  TJpegOutputMessage = procedure(cinfo: PRJpegCommonStruct); cdecl;
  TJpegFormatMessage = procedure(cinfo: PRJpegCommonStruct; Buffer: Pointer); cdecl;
  TJpegResetErrorMgr = procedure(cinfo: PRJpegCommonStruct); cdecl;

  RJpegErrorMgrMsgParm = record
  case Boolean of
    False: (MsgParmI: array[0..7] of Integer);
    True: (MsgParmS: array[0..JMSG_STR_PARM_MAX-1] of AnsiChar);
  end;

  RJpegErrorMgr = record
    ErrorExit: TJpegErrorExit;         { Error exit handler: does not return to caller }
    EmitMessage: TJpegEmitMessage;     { Conditionally emit a trace or warning message }
    OutputMessage: TJpegOutputMessage; { Routine that actually outputs a trace or error message }
    FormatMessage: TJpegFormatMessage; { Format a message string for the most recent JPEG error or message }
    ResetErrorMgr: TJpegResetErrorMgr; { Reset error state variables at start of a new image }
    { The message ID code and any parameters are saved here. A message can have one string parameter or up to 8 int parameters. }
    MsgCode: Integer;
    MsgParm: RJpegErrorMgrMsgParm;
    { Standard state variables for error facility }
    TraceLevel: Integer; {max msg_level that will be displayed}
    { For recoverable corrupt-data errors, we emit a warning message, but keep going unless emit_message chooses to abort.
      emit_message should count warnings in num_warnings.  The surrounding application can check for bad data by seeing if num_warnings
      is nonzero at the end of processing. }
    NumWarnings: Integer;    { number of corrupt-data warnings }
    { These fields point to the table(s) of error message strings. An application can change the table pointer to switch to a different
      message list (typically, to change the language in which errors are reported).  Some applications may wish to add additional
      error codes that will be handled by the JPEG library error mechanism; the second table pointer is used for this purpose.
      First table includes all errors generated by JPEG library itself. Error code 0 is reserved for a "no such error string" message. }
    JpegMessageTable: PPAnsiChar;      { Library errors }
    LastJpegMessage: Integer;      { Table contains strings 0..last_jpeg_message }
    { Second table can be added by application (see cjpeg/djpeg for example). It contains strings numbered
      first_addon_message..last_addon_message. }
    AddonMessageTable: PPAnsiChar;     { Non-library errors }
    FirstAddonMessage: Integer;    { code for first string in addon table }
    LastAddonMessage: Integer;     { code for last string in addon table }
  end;

  TJpegInitDestination = procedure(cinfo: PRJpegCompressStruct); cdecl;
  TJpegEmptyOutputBuffer = function(cinfo: PRJpegCompressStruct): Boolean; cdecl;
  TJpegTermDestination = procedure(cinfo: PRJpegCompressStruct); cdecl;

  RJpegDestinationMgr = record
    NextOutputByte: Pointer;       { => next byte to write in buffer }
    FreeInBuffer: Cardinal;        { # of byte spaces remaining in buffer }
    InitDestination: TJpegInitDestination;
    EmptyOutputBuffer: TJpegEmptyOutputBuffer;
    TermDestination: TJpegTermDestination;
  end;

  TJpegInitSource = procedure(cinfo: PRJpegDecompressStruct); cdecl;
  TJpegFillInputBuffer = function(cinfo: PRJpegDecompressStruct): Boolean; cdecl;
  TJpegSkipInputData = procedure(cinfo: PRJpegDecompressStruct; NumBytes: Integer); cdecl;
  TJpegResyncToRestart = function(cinfo: PRJpegDecompressStruct; Desired: Integer): Boolean; cdecl;
  TJpegTermSource = procedure(cinfo: PRJpegDecompressStruct); cdecl;

  RJpegSourceMgr = record
    NextInputByte: Pointer;
    BytesInBuffer: Cardinal;
    InitSource: TJpegInitSource;
    FillInputBuffer: TJpegFillInputBuffer;
    SkipInputData: TJpegSkipInputData;
    ResyncToRestart: TJpegResyncToRestart;
    TermSource: TJpegTermSource;
  end;

  RJpegComponentInfo = record
    { Basic info about one component (color channel). }
    { These values are fixed over the whole image. }
    { For compression, they must be supplied by parameter setup; }
    { for decompression, they are read from the SOF marker. }
    ComponentId: Integer;          { identifier for this component (0..255) }
    ComponentIndex: Integer;       { its index in SOF or cinfo->comp_info[] }
    HSampFactor: Integer;          { horizontal sampling factor (1..4) }
    VSampFactor: Integer;          { vertical sampling factor (1..4) }
    QuantTblNo: Integer;           { quantization table selector (0..3) }
    { These values may vary between scans. }
    { For compression, they must be supplied by parameter setup; }
    { for decompression, they are read from the SOS marker. }
    { The decompressor output side may not use these variables. }
    DcTblNo: Integer;              { DC entropy table selector (0..3) }
    AsTblNo: Integer;              { AC entropy table selector (0..3) }
    { Remaining fields should be treated as private by applications. }
    { These values are computed during compression or decompression startup: }
    { Component's size in DCT blocks. Any dummy blocks added to complete an MCU are not counted; therefore these values do not depend
      on whether a scan is interleaved or not. }
    WidthInBlocks: Cardinal;
    HeightInBlocks: Cardinal;
    { Size of a DCT block in samples.  Always DCTSIZE for compression. For decompression this is the size of the output from one DCT
      block, reflecting any scaling we choose to apply during the IDCT step. Values of 1,2,4,8 are likely to be supported.  Note that
      different components may receive different IDCT scalings. }
    DctScaledSize: Integer;
    { The downsampled dimensions are the component's actual, unpadded number of samples at the main buffer (preprocessing/compression
      interface), thus downsampled_width = ceil(image_width * Hi/Hmax) and similarly for height.  For decompression, IDCT scaling is
      included, so downsampled_width = ceil(image_width * Hi/Hmax * DCT_scaled_size/DCTSIZE) }
    DownsampledWidth: Cardinal;    { actual width in samples }
    DownsampledHeight: Cardinal;   { actual height in samples }
    { This flag is used only for decompression.  In cases where some of the components will be ignored (eg grayscale output from YCbCr
      image), we can skip most computations for the unused components. }
    ComponentNeeded: Boolean;      { do we need the value of this component? }
    { These values are computed before starting a scan of the component. }
    { The decompressor output side may not use these variables. }
    McuWidth: Integer;             { number of blocks per MCU, horizontally }
    McuHeight: Integer;            { number of blocks per MCU, vertically }
    McuBlocks: Integer;            { MCU_width * MCU_height }
    McuSampleWidth: Integer;       { MCU width in samples, MCU_width*DCT_scaled_size }
    LastColWidth: Integer;         { # of non-dummy blocks across in last MCU }
    LastRowHeight: Integer;        { # of non-dummy blocks down in last MCU }
    { Saved quantization table for component; NULL if none yet saved. See jdinput.c comments about the need for this information. This
      field is currently used only for decompression. }
    QuantTable: PRJpegQuantTbl;
    { Private per-component storage for DCT or IDCT subsystem. }
    DctTable: Pointer;
  end;

  RJpegCommonStruct = record
    Err: PRJpegErrorMgr;           { Error handler module }
    Mem: PRJpegMemoryMgr;          { Memory manager module }
    Progress: PRJpegProgressMgr;   { Progress monitor, or NULL if none }
    ClientData: Pointer;           { Available for use by application }
    IsDecompressor: Boolean;       { So common code can tell which is which }
    GlobalState: Integer;          { For checking call sequence validity }
  end;

  RJpegCompressStruct = record
    Err: PRJpegErrorMgr;           { Error handler module }
    Mem: PRJpegMemoryMgr;          { Memory manager module }
    Progress: PRJpegProgressMgr;   { Progress monitor, or NULL if none }
    ClientData: Pointer;           { Available for use by application }
    IsDecompressor: Boolean;       { So common code can tell which is which }
    GlobalState: Integer;          { For checking call sequence validity }
    { Destination for compressed data }
    Dest: PRJpegDestinationMgr;
    { Description of source image --- these fields must be filled in by outer application before starting compression.
      in_color_space must be correct before you can even call jpeg_set_defaults(). }
    ImageWidth: Cardinal;          { input image width }
    ImageHeight: Cardinal;         { input image height }
    InputComponents: Integer;      { # of color components in input image }
    InColorSpace: Integer;         { colorspace of input image }
    InputGamme: Double;            { image gamma of input image }
    { Compression parameters --- these fields must be set before calling jpeg_start_compress().  We recommend calling
      jpeg_set_defaults() to initialize everything to reasonable defaults, then changing anything the application specifically wants
      to change.  That way you won't get burnt when new parameters are added.  Also note that there are several helper routines to
      simplify changing parameters. }
    DataPrecision: Integer;        { bits of precision in image data }
    NumComponents: Integer;        { # of color components in JPEG image }
    JpegColorSpace: Integer;       { colorspace of JPEG image }
    CompInfo: PRJpegComponentInfo; { comp_info[i] describes component that appears i'th in SOF }
    QuantTblPtrs: array[0..NUM_QUANT_TBLS-1] of PRJpegQuantTbl;   {ptrs to coefficient quantization tables, or NULL if not defined }
    DcHuffTblPtrs: array[0..NUM_HUFF_TBLS-1] of PRJpegHuffTbl;    {ptrs to Huffman coding tables, or NULL if not defined }
    AcHuffTblPtrs: array[0..NUM_HUFF_TBLS-1] of PRJpegHuffTbl;
    ArithDcL: array[0..NUM_ARITH_TBLS-1] of Byte;                 { L values for DC arith-coding tables }
    ArithDcU: array[0..NUM_ARITH_TBLS-1] of Byte;                 { U values for DC arith-coding tables }
    ArithAcK: array[0..NUM_ARITH_TBLS-1] of Byte;                 { Kx values for AC arith-coding tables }
    NumScans: Integer;             { # of entries in scan_info array }
    ScanInfo: PRJpegScanInfo;      { script for multi-scan file, or NULL }
    { The default value of scan_info is NULL, which causes a single-scan sequential JPEG file to be emitted.  To create a multi-scan
      file, set num_scans and scan_info to point to an array of scan definitions. }
    RawDataIn: Boolean;            { TRUE=caller supplies downsampled data }
    ArithCode: Boolean;            { TRUE=arithmetic coding, FALSE=Huffman }
    OptimizeCoding: Boolean;       { TRUE=optimize entropy encoding parms }
    CCIR601Sampling: Boolean;      { TRUE=first samples are cosited }
    SmoothingFactor: Integer;      { 1..100, or 0 for no input smoothing }
    DctMethod: Integer;            { DCT algorithm selector }
    { The restart interval can be specified in absolute MCUs by setting restart_interval, or in MCU rows by setting restart_in_rows
      (in which case the correct restart_interval will be figured for each scan). }
    RestartInterval: Cardinal;     { MCUs per restart, or 0 for no restart }
    RestartInRows: Integer;        { if > 0, MCU rows per restart interval }
    { Parameters controlling emission of special markers. }
    WriteJfifHeader: Boolean;      { should a JFIF marker be written? }
    JfifMajorVersion: Byte;        { What to write for the JFIF version number }
    JFifMinorVersion: Byte;
    { These three values are not used by the JPEG code, merely copied  into the JFIF APP0 marker.  density_unit can be 0 for unknown,
      1 for dots/inch, or 2 for dots/cm.  Note that the pixel aspect ratio is defined by X_density/Y_density even when density_unit=0. }
    DensityUnit: Byte;             { JFIF code for pixel size units }
    XDensity: Word;                { Horizontal pixel density }
    YDensity: WOrd;                { Vertical pixel density }
    WriteAdobeMarker: Boolean;     { should an Adobe marker be written? }
    { State variable: index of next scanline to be written to jpeg_write_scanlines().  Application may use this to control its
      processing loop, e.g., "while (next_scanline < image_height)". }
    NextScanline: Cardinal;        { 0 .. image_height-1  }
    { Remaining fields are known throughout compressor, but generally should not be touched by a surrounding application. }
    { These fields are computed during compression startup }
    ProgressiveMode: Boolean;      { TRUE if scan script uses progressive mode }
    MaxHSampFactor: Integer;       { largest h_samp_factor }
    MaxVSampFactor: Integer;       { largest v_samp_factor }
    TotalIMCURows: Cardinal;       { # of iMCU rows to be input to coef ctlr }
    { The coefficient controller receives data in units of MCU rows as defined for fully interleaved scans (whether the JPEG file is
      interleaved or not). There are v_samp_factor * DCTSIZE sample rows of each component in an "iMCU" (interleaved MCU) row. }
    { These fields are valid during any one scan. They describe the components and MCUs actually appearing in the scan. }
    CompsInScan: Integer;          { # of JPEG components in this scan }
    CurCompInfo: array[0..MAX_COMPS_IN_SCAN-1] of PRJpegComponentInfo;
    { *cur_comp_info[i] describes component that appears i'th in SOS }
    MCUsPerRow: Cardinal;          { # of MCUs across the image }
    MCUsRowsInScan: Cardinal;      { # of MCU rows in the image }
    BlocksInMcu: Integer;          { # of DCT blocks per MCU }
    MCUMembership: array[0..C_MAX_BLOCKS_IN_MCU-1] of Integer;
    { MCU_membership[i] is index in cur_comp_info of component owning i'th block in an MCU }
    Ss,Se,Ah,Al: Integer;          { progressive JPEG parameters for scan }
    { Links to compression subobjects (methods and private variables of modules) }
    Master: PRJpegCompMaster;
    Main: PRJpegCMainController;
    Prep: PRJpegCPrepController;
    Coef: PRJpegCCoefController;
    Marker: PRJpegMarkerWriter;
    CConvert: PRJpegColorConverter;
    Downsample: PRJpegDownsampler;
    FDct: PRJpegForwardDct;
    Entropy: PRJpegEntropyEncoder;
    ScriptSpace: PRJpegScanInfo;   { workspace for jpeg_simple_progression }
    ScriptSpaceSize: Integer;
  end;

  RJpegDecompressStruct = record
    { Fields shared with jpeg_compress_struct }
    Err: PRJpegErrorMgr;           { Error handler module }
    Mem: PRJpegMemoryMgr;          { Memory manager module }
    Progress: PRJpegProgressMgr;   { Progress monitor, or NULL if none }
    ClientData: Pointer;           { Available for use by application }
    IsDecompressor: Boolean;       { So common code can tell which is which }
    GlobalState: Integer;          { For checking call sequence validity }
    { Source of compressed data }
    Src: PRJpegSourceMgr;
    { Basic description of image --- filled in by jpeg_read_header(). }
    { Application may inspect these values to decide how to process image. }
    ImageWidth: Cardinal;          { nominal image width (from SOF marker) }
    ImageHeight: Cardinal;         { nominal image height }
    NumComponents: Integer;        { # of color components in JPEG image }
    JpegColorSpace: Integer;       { colorspace of JPEG image }
    { Decompression processing parameters --- these fields must be set before calling jpeg_start_decompress().  Note that
      jpeg_read_header() initializes them to default values. }
    OutColorSpace: Integer;        { colorspace for output }
    ScaleNum,ScaleDenom: Cardinal; { fraction by which to scale image }
    OutputGamme: Double;           { image gamma wanted in output }
    BufferedImage: Boolean;        { TRUE=multiple output passes }
    RawDataOut: Boolean;           { TRUE=downsampled data wanted }
    DctMethod: Integer;            { IDCT algorithm selector }
    DoFancyUpsampling: Boolean;    { TRUE=apply fancy upsampling }
    DoBlockSmoothing: Boolean;     { TRUE=apply interblock smoothing }
    QuantizeColors: Boolean;       { TRUE=colormapped output wanted }
    { the following are ignored if not quantize_colors: }
    DitherMode: Integer;           { type of color dithering to use }
    TwoPassQuantize: Boolean;      { TRUE=use two-pass color quantization }
    DesiredNumberOfColors: Integer;{ max # colors to use in created colormap }
    { these are significant only in buffered-image mode: }
    Enable1PassQuant: Boolean;     { enable future use of 1-pass quantizer }
    EnableExternalQuant: Boolean;  { enable future use of external colormap }
    Enable2PassQuant: Boolean;     { enable future use of 2-pass quantizer }
    { Description of actual output image that will be returned to application. These fields are computed by jpeg_start_decompress().
      You can also use jpeg_calc_output_dimensions() to determine these values in advance of calling jpeg_start_decompress(). }
    OutputWidth: Cardinal;         { scaled image width }
    OutputHeight: Cardinal;        { scaled image height }
    OutColorComponents: Integer;   { # of color components in out_color_space }
    OutputComponents: Integer;     { # of color components returned }
    { output_components is 1 (a colormap index) when quantizing colors; otherwise it equals out_color_components. }
    RecOutbufHeight: Integer;      { min recommended height of scanline buffer }
    { If the buffer passed to jpeg_read_scanlines() is less than this many rows high, space and time will be wasted due to unnecessary
      data copying. Usually rec_outbuf_height will be 1 or 2, at most 4. }
    { When quantizing colors, the output colormap is described by these fields. The application can supply a colormap by setting
      colormap non-NULL before calling jpeg_start_decompress; otherwise a colormap is created during jpeg_start_decompress or
      jpeg_start_output. The map has out_color_components rows and actual_number_of_colors columns. }
    ActualNumberOfColors: Integer; { number of entries in use }
    Colormap: Pointer;             { The color map as a 2-D pixel array }
    { State variables: these variables indicate the progress of decompression. The application may examine these but must not modify
      them. }
    { Row index of next scanline to be read from jpeg_read_scanlines(). Application may use this to control its processing loop, e.g.,
      "while (output_scanline < output_height)". }
    OutputScanline: Cardinal;      { 0 .. output_height-1 }
    { Current input scan number and number of iMCU rows completed in scan. These indicate the progress of the decompressor input side. }
    InputScanNumber: Integer;      { Number of SOS markers seen so far }
    InputIMcuRow: Cardinal;        { Number of iMCU rows completed }
    { The "output scan number" is the notional scan being displayed by the output side.  The decompressor will not allow output
      scan/row number to get ahead of input scan/row, but it can fall arbitrarily far behind. }
    OutputScanNumber: Integer;     { Nominal scan number being displayed }
    OutputIMcuRow: Cardinal;       { Number of iMCU rows read }
    { Current progression status.  coef_bits[c][i] indicates the precision with which component c's DCT coefficient i (in zigzag order)
      is known. It is -1 when no data has yet been received, otherwise it is the point transform (shift) value for the most recent scan
      of the coefficient (thus, 0 at completion of the progression). This pointer is NULL when reading a non-progressive file. }
    CoefBits: Pointer;             { -1 or current Al value for each coef }
    { Internal JPEG parameters --- the application usually need not look at these fields.  Note that the decompressor output side may
      not use any parameters that can change between scans. }
    { Quantization and Huffman tables are carried forward across input datastreams when processing abbreviated JPEG datastreams. }
    QuantTblPtrs: array[0..NUM_QUANT_TBLS-1] of Pointer;
    { ptrs to coefficient quantization tables, or NULL if not defined }
    DcHuffTblPtrs: array[0..NUM_HUFF_TBLS-1] of Pointer;
    AcHuffTblPtrs: array[0..NUM_HUFF_TBLS-1] of Pointer;
    { ptrs to Huffman coding tables, or NULL if not defined }
    { These parameters are never carried across datastreams, since they are given in SOF/SOS markers or defined to be reset by SOI. }
    DataPrecision: Integer;        { bits of precision in image data }
    CompInfo: PRJpegComponentInfo; { comp_info[i] describes component that appears i'th in SOF }
    ProgressiveMode: Boolean;      { TRUE if SOFn specifies progressive mode }
    ArithCode: Boolean;            { TRUE=arithmetic coding, FALSE=Huffman }
    ArithDcL: array[0..NUM_ARITH_TBLS-1] of Byte;       { L values for DC arith-coding tables }
    ArithDcY: array[0..NUM_ARITH_TBLS-1] of Byte;       { U values for DC arith-coding tables }
    ArithAcK: array[0..NUM_ARITH_TBLS-1] of Byte;       { Kx values for AC arith-coding tables }
    RestartInterval: Cardinal;     { MCUs per restart interval, or 0 for no restart }
    { These fields record data obtained from optional markers recognized by the JPEG library. }
    SawJfifMarker: Boolean;        { TRUE iff a JFIF APP0 marker was found }
    { Data copied from JFIF marker; only valid if saw_JFIF_marker is TRUE: }
    JfifMajorVersion: Byte;        { JFIF version number }
    JfifMinorVersion: Byte;        { JFIF code for pixel size units }
    XDensity: Word;                { Horizontal pixel density }
    YDensity: Word;                { Vertical pixel density }
    SawAdobeMarker: Boolean;       { TRUE iff an Adobe APP14 marker was found }
    AdobeTransform: Byte;          { Color transform code from Adobe marker }
    Ccir601Sampling: Boolean;      { TRUE=first samples are cosited }
    { Aside from the specific data retained from APPn markers known to the library, the uninterpreted contents of any or all APPn and
      COM markers can be saved in a list for examination by the application. }
    MarkerList: PRJpegSavedMarker; { Head of list of saved markers }
    { Remaining fields are known throughout decompressor, but generally should not be touched by a surrounding application. }
    { These fields are computed during decompression startup }
    MaxHSampFactor: Integer;       { largest h_samp_factor }
    MaxVSampFactor: Integer;       { largest v_samp_factor }
    MinDctScaledSize: Integer;     { smallest DCT_scaled_size of any component }
    TotalIMcuRows: Cardinal;       { # of iMCU rows in image }
    { The coefficient controller's input and output progress is measured in units of "iMCU" (interleaved MCU) rows.  These are the same
      as MCU rows in fully interleaved JPEG scans, but are used whether the scan is interleaved or not.  We define an iMCU row as
      v_samp_factor DCT block rows of each component.  Therefore, the IDCT output contains v_samp_factor*DCT_scaled_size sample rows
      of a component per iMCU row. }
    SampleRangeLimit: Pointer;     { table for fast range-limiting }
    { These fields are valid during any one scan. They describe the components and MCUs actually appearing in the scan. Note that the
      decompressor output side must not use these fields. }
    CompsInScan: Integer;          { # of JPEG components in this scan }
    CurCompInfo: array[0..MAX_COMPS_IN_SCAN-1] of PRJpegComponentInfo;
    { *cur_comp_info[i] describes component that appears i'th in SOS }
    McusPerRow: Cardinal;          { # of MCUs across the image }
    McuRowsInScan: Cardinal;       { # of MCU rows in the image }
    BlocksInMcu: Integer;          { # of DCT blocks per MCU }
    McuMembership: array[0..D_MAX_BLOCKS_IN_MCU-1] of Integer;
    { MCU_membership[i] is index in cur_comp_info of component owning  i'th block in an MCU }
    Ss,Se,Ah,Al: Integer;          { progressive JPEG parameters for scan }
    { This field is shared between entropy decoder and marker parser. It is either zero or the code of a JPEG marker that has been read
      from the data source, but has not yet been processed. }
    UnreadMarker: Integer;
    { Links to decompression subobjects (methods, private variables of modules) }
    Master: PRJpegDecompMaster;
    Main: PRJpegDMainController;
    Coef: PRJpegDCoefController;
    Post: PRJpegDPosController;
    InputCtl: PRJpegInputController;
    Marker: PRJpegMarkerReader;
    Entropy: PRJpegEntropyDecoder;
    IDct: PRJpegInverseDct;
    Upsample: PRJpegUpsampler;
    CConvert: PRJpegColorDeconverter;
    CQuantize: PRJpegColorQuantizer;
  end;

procedure jpeg_create_compress(cinfo: PRJpegCompressStruct); cdecl;
procedure jpeg_CreateCompress(cinfo: PRJpegCompressStruct; version: Integer; structsize: Cardinal); cdecl; external;
procedure jpeg_create_decompress(cinfo: PRJpegDecompressStruct); cdecl;
procedure jpeg_CreateDecompress(cinfo: PRJpegDecompressStruct; version: Integer; structsize: Cardinal); cdecl; external;
procedure jpeg_abort(cinfo: PRJpegCommonStruct); cdecl; external;
procedure jpeg_set_defaults(cinfo: PRJpegCompressStruct); cdecl; external;
procedure jpeg_set_colorspace(cinfo: PRJpegCompressStruct; colorspace: Integer); cdecl; external;
procedure jpeg_set_quality(cinfo: PRJpegCompressStruct; quality: Integer; force_baseline: Byte); cdecl; external;
procedure jpeg_suppress_tables(cinfo: PRJpegCompressStruct; suppress: Byte); cdecl; external;
procedure jpeg_start_compress(cinfo: PRJpegCompressStruct; write_all_tables: Byte); cdecl; external;
function  jpeg_write_scanlines(cinfo: PRJpegCompressStruct; scanlines: PPointer; num_lines: Cardinal): Cardinal; cdecl; external;
function  jpeg_write_raw_data(cinfo: PRJpegCompressStruct; data: Pointer; num_lines: Cardinal): Cardinal; cdecl; external;
procedure jpeg_finish_compress(cinfo: PRJpegCompressStruct); cdecl; external;
procedure jpeg_write_tables(cinfo: PRJpegCompressStruct); cdecl; external;
function  jpeg_read_header(cinfo: PRJpegDecompressStruct; require_image: Boolean): Integer; cdecl; external;
function  jpeg_start_decompress(cinfo: PRJpegDecompressStruct): Byte; cdecl; external;
function  jpeg_read_scanlines(cinfo: PRJpegDecompressStruct; scanlines: Pointer; max_lines: Cardinal): Cardinal; cdecl; external;
function  jpeg_read_raw_data(cinfo: PRJpegDecompressStruct; data: Pointer; max_lines: Cardinal): Cardinal; cdecl; external;
function  jpeg_finish_decompress(cinfo: PRJpegDecompressStruct): Byte; cdecl; external;
procedure jpeg_destroy(cinfo: PRJpegCommonStruct); cdecl; external;
function  jpeg_std_error(err: PRJpegErrorMgr): Pointer; cdecl; external;
function  jpeg_resync_to_restart(cinfo: PRJpegDecompressStruct; desired: Integer): Byte; cdecl; external;

implementation

uses
  LibDelphi;

procedure jpeg_error_exit_raise; cdecl; {$ifdef FPC}[public];{$endif}
begin
  raise Exception.Create('LibJpeg error_exit');
end;

{$ifdef FPC}
function jpeg_sizeof_compress:Integer; cdecl; external;
function jpeg_sizeof_decompress:Integer; cdecl; external;

procedure jpeg_create_compress(cinfo: PRJpegCompressStruct); cdecl;
begin
  jpeg_CreateCompress(cinfo,JPEG_LIB_VERSION,jpeg_sizeof_compress());
end;

procedure jpeg_create_decompress(cinfo: PRJpegDecompressStruct); cdecl;
begin
  jpeg_CreateDecompress(cinfo,JPEG_LIB_VERSION,jpeg_sizeof_decompress());
end;
{$else}
procedure jpeg_create_compress(cinfo: PRJpegCompressStruct); cdecl;
begin
  jpeg_CreateCompress(cinfo,JPEG_LIB_VERSION,SizeOf(RJpegCompressStruct));
end;

procedure jpeg_create_decompress(cinfo: PRJpegDecompressStruct); cdecl;
begin
  jpeg_CreateDecompress(cinfo,JPEG_LIB_VERSION,SizeOf(RJpegDecompressStruct));
end;
{$endif}

function  jpeg_get_small(cinfo: PRJpegCommonStruct; sizeofobject: Cardinal): Pointer; cdecl; external;
function  jpeg_get_large(cinfo: PRJpegCommonStruct; sizeofobject: Cardinal): Pointer; cdecl; external;
function  jpeg_mem_available(cinfo: PRJpegCommonStruct; min_bytes_needed: Integer; max_bytes_needed: Integer; already_allocated: Integer): Integer; cdecl; external;
procedure jpeg_open_backing_store(cinfo: PRJpegCommonStruct; info: Pointer; total_bytes_needed: Integer); cdecl; external;
procedure jpeg_free_large(cinfo: PRJpegCommonStruct; objectt: Pointer; sizeofobject: Cardinal); cdecl; external;
procedure jpeg_free_small(cinfo: PRJpegCommonStruct; objectt: Pointer; sizeofobject: Cardinal); cdecl; external;
procedure jpeg_mem_term(cinfo: PRJpegCommonStruct); cdecl; external;
function  jpeg_mem_init(cinfo: PRJpegCommonStruct): Integer; cdecl; external;
procedure jinit_memory_mgr(cinfo: PRJpegCommonStruct); cdecl; external;
function  jpeg_alloc_huff_table(cinfo: PRJpegCommonStruct): Pointer; cdecl; external;
function  jpeg_alloc_quant_table(cinfo: PRJpegCommonStruct): Pointer; cdecl; external;
function  jdiv_round_up(a: Integer; b: Integer): Integer; cdecl; external;
procedure jcopy_sample_rows(input_array: Pointer; source_row: Integer; output_array: Pointer; dest_row: Integer; num_rows: Integer;
               num_cols: Cardinal); cdecl; external;
function  jround_up(a: Integer; b: Integer): Integer; cdecl; external;
procedure jcopy_block_row(input_row: Pointer; output_row: Pointer; num_blocks: Cardinal); cdecl; external;

{$IF Defined(DCC) and Defined(MSWINDOWS) and not Defined(CPUX64)}
  // Windows 32bit Delphi only - OMF object format
  {$L Compiled\jmemnobs.obj}
  {$L Compiled\jmemmgr.obj}
  {$L Compiled\jcomapi.obj}
  {$L Compiled\jerror.obj}
  {$L Compiled\jcapimin.obj}
  {$L Compiled\jcmarker.obj}
  {$L Compiled\jutils.obj}
  {$L Compiled\jdapimin.obj}
  {$L Compiled\jdmarker.obj}
  {$L Compiled\jdinput.obj}
  {$L Compiled\jcparam.obj}
  {$L Compiled\jcapistd.obj}
  {$L Compiled\jcinit.obj}
  {$L Compiled\jcmaster.obj}
  {$L Compiled\jccolor.obj}
  {$L Compiled\jcsample.obj}
  {$L Compiled\jcprepct.obj}
  {$L Compiled\jcdctmgr.obj}
  {$L Compiled\jcphuff.obj}
  {$L Compiled\jchuff.obj}
  {$L Compiled\jccoefct.obj}
  {$L Compiled\jcmainct.obj}
  {$L Compiled\jfdctint.obj}
  {$L Compiled\jfdctfst.obj}
  {$L Compiled\jfdctflt.obj}
  {$L Compiled\jdapistd.obj}
  {$L Compiled\jdmaster.obj}
  {$L Compiled\jquant1.obj}
  {$L Compiled\jquant2.obj}
  {$L Compiled\jdmerge.obj}
  {$L Compiled\jdcolor.obj}
  {$L Compiled\jdsample.obj}
  {$L Compiled\jdpostct.obj}
  {$L Compiled\jddctmgr.obj}
  {$L Compiled\jdphuff.obj}
  {$L Compiled\jdhuff.obj}
  {$L Compiled\jdcoefct.obj}
  {$L Compiled\jdmainct.obj}
  {$L Compiled\jidctred.obj}
  {$L Compiled\jidctint.obj}
  {$L Compiled\jidctfst.obj}
  {$L Compiled\jidctflt.obj}
{$IFEND}
end.



