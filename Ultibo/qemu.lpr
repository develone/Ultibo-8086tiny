program qemu;

{$mode objfpc}{$H+}

{$IFNDEF PLATFORM_PI3}
  {$IFNDEF PLATFORM_PI2}
    {$DEFINE PLATFORM_QEMU}
  {$ENDIF}
{$ENDIF}

uses
{$IFDEF PLATFORM_PI2}
  RaspberryPi2,
  Updater,
{$ENDIF}
{$IFDEF PLATFORM_PI3}
  RaspberryPi3,
  Updater,
{$ENDIF}
{$IFDEF PLATFORM_QEMU}
  QEMUVersatilePB,
{$ENDIF}
  GlobalConfig,
  GlobalConst,
  GlobalTypes,
  Platform,
  Threads,
  SysUtils,
  Classes,
  Ultibo,
  Syscalls,
  Console,
  FileSystem,
  FATFS,
  MMC,
  Framebuffer,
  keyboard,
  Font,
  Fixedsys_16;

{$linklib 8086tiny}

var
  WindowHandle          : TWindowHandle;
  FramebufferDevice     : PFramebufferDevice;
  FramebufferProperties : TFramebufferProperties;
  BufferStart           : Pointer;
  Bios                  : TFileStream;
  Floppy                : TFileStream;
  LastTick              : ULONGLONG;
  PageSize              : Integer;
  CurrentPage           : Integer;

  GfxWidth, GfxHeight   : Integer;

  inANSI                : Boolean;
  inCSI                 : Boolean;
  csi                   : String;

const BIOS_HANDLE = 100;
const FLOPPY_HANDLE = 101;
const STD_IN = 0;

const
 VGAPalette:TFramebufferPalette = (
  Start:0;
  Count:256;
  Entries:
  ($FF000000,$FF0000AA,$FF00AA00,$FF00AAAA,$FFAA0000,$FFAA00AA,$FFAA5500,$FFAAAAAA,$FF555555,$FF5555FF,$FF55FF55,$FF55FFFF,$FFFF5555,$FFFF55FF,$FFFFFF55,$FFFFFFFF,
   $FF000000,$FF141414,$FF202020,$FF2C2C2C,$FF383838,$FF444444,$FF505050,$FF606060,$FF707070,$FF808080,$FF909090,$FFA0A0A0,$FFB4B4B4,$FFC8C8C8,$FFE0E0E0,$FFFCFCFC,
   $FF0000FC,$FF4000FC,$FF7C00FC,$FFBC00FC,$FFFC00FC,$FFFC00BC,$FFFC007C,$FFFC0040,$FFFC0000,$FFFC4000,$FFFC7C00,$FFFCBC00,$FFFCFC00,$FFBCFC00,$FF7CFC00,$FF40FC00,
   $FF00FC00,$FF00FC40,$FF00FC7C,$FF00FCBC,$FF00FCFC,$FF00BCFC,$FF007CFC,$FF0040FC,$FF7C7CFC,$FF9C7CFC,$FFBC7CFC,$FFDC7CFC,$FFFC7CFC,$FFFC7CDC,$FFFC7CBC,$FFFC7C9C,
   $FFFC7C7C,$FFFC9C7C,$FFFCBC7C,$FFFCDC7C,$FFFCFC7C,$FFDCFC7C,$FFBCFC7C,$FF9CFC7C,$FF7CFC7C,$FF7CFC9C,$FF7CFCBC,$FF7CFCDC,$FF7CFCFC,$FF7CDCFC,$FF7CBCFC,$FF7C9CFC,
   $FFB4B4FC,$FFC4B4FC,$FFD8B4FC,$FFE8B4FC,$FFFCB4FC,$FFFCB4E8,$FFFCB4D8,$FFFCB4C4,$FFFCB4B4,$FFFCC4B4,$FFFCD8B4,$FFFCE8B4,$FFFCFCB4,$FFE8FCB4,$FFD8FCB4,$FFC4FCB4,
   $FFB4FCB4,$FFB4FCC4,$FFB4FCD8,$FFB4FCE8,$FFB4FCFC,$FFB4E8FC,$FFB4D8FC,$FFB4C4FC,$FF000070,$FF1C0070,$FF380070,$FF540070,$FF700070,$FF700054,$FF700038,$FF70001C,
   $FF700000,$FF701C00,$FF703800,$FF705400,$FF707000,$FF547000,$FF387000,$FF1C7000,$FF007000,$FF00701C,$FF007038,$FF007054,$FF007070,$FF005470,$FF003870,$FF001C70,
   $FF383870,$FF443870,$FF543870,$FF603870,$FF703870,$FF703860,$FF703854,$FF703844,$FF703838,$FF704438,$FF705438,$FF706038,$FF707038,$FF607038,$FF547038,$FF447038,
   $FF387038,$FF387044,$FF387054,$FF387060,$FF387070,$FF386070,$FF385470,$FF384470,$FF505070,$FF585070,$FF605070,$FF685070,$FF705070,$FF705068,$FF705060,$FF705058,
   $FF705050,$FF705850,$FF706050,$FF706850,$FF707050,$FF687050,$FF607050,$FF587050,$FF507050,$FF507058,$FF507060,$FF507068,$FF507070,$FF506870,$FF506070,$FF505870,
   $FF000040,$FF100040,$FF200040,$FF300040,$FF400040,$FF400030,$FF400020,$FF400010,$FF400000,$FF401000,$FF402000,$FF403000,$FF404000,$FF304000,$FF204000,$FF104000,
   $FF004000,$FF004010,$FF004020,$FF004030,$FF004040,$FF003040,$FF002040,$FF001040,$FF202040,$FF282040,$FF302040,$FF382040,$FF402040,$FF402038,$FF402030,$FF402028,
   $FF402020,$FF402820,$FF403020,$FF403820,$FF404020,$FF384020,$FF304020,$FF284020,$FF204020,$FF204028,$FF204030,$FF204038,$FF204040,$FF203840,$FF203040,$FF202840,
   $FF2C2C40,$FF302C40,$FF342C40,$FF3C2C40,$FF402C40,$FF402C3C,$FF402C34,$FF402C30,$FF402C2C,$FF40302C,$FF40342C,$FF403C2C,$FF40402C,$FF3C402C,$FF34402C,$FF30402C,
   $FF2C402C,$FF2C4030,$FF2C4034,$FF2C403C,$FF2C4040,$FF2C3C40,$FF2C3440,$FF2C3040,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000,$FF000000)
  );


function LOOP(bios, fdd, hdd : pchar; bootFromFloppy : integer) : integer; cdecl; external 'lib8086tiny' name 'LOOP';

function Emu_printChar(ch : char) : integer; export; cdecl;
begin
  Result := 0;

  if (inCSI) then
  begin
    csi := csi + ch;
    if (csi[1] <> '?') then
    begin
      inCSI := False;
    end else
    case csi of
        '?25h':
        begin
          inCSI := False;
          ConsoleWindowCursorOn(WindowHandle);
          exit;
        end;

        '?25l':
        begin
          inCSI := False;
          ConsoleWindowCursorOff(WindowHandle);
          exit;
        end;

        '?1049h', '1049l', '2004h', '2004l':
        begin
          inCSI := False;
          exit;
        end;
    else
      begin
        exit;
      end;
    end;
  end;

  if (inANSI) then
  begin
    inANSI := False;
    if (ch = '[') then
    begin
      inCSI := True;
      csi := '';
      exit;
    end;

    ConsoleWindowWrite(WindowHandle, chr(27)); //we didn't write the escape that got us here, so catch up quickly
    exit;
  end;

  case ord(ch) of
    8   : ConsoleWindowSetX(WindowHandle, ConsoleWindowGetX(WindowHandle)-1);
    13  : ConsoleWindowWriteLn(WindowHandle,'');
    27 : inANSI := True;
    else ConsoleWindowWrite(WindowHandle, ch);
  end;
end;

function Emu_putint(i : int) : integer; export; cdecl;
begin
  Result := 0;
  writeln(i);
end;

function Emu_enterTextMode() : integer; export; cdecl;
begin
  Result := 0;
  writeln('text');

  FramebufferDeviceRelease(FramebufferDevice);
  FRAMEBUFFER_CONSOLE_AUTOCREATE := True;

  FramebufferDevice := FramebufferDeviceGetDefault;
  FramebufferDeviceGetProperties(FramebufferDevice, @FramebufferProperties);
  Sleep(500);
  FramebufferProperties.Depth := 32;
  FramebufferProperties.VirtualWidth:= FramebufferProperties.PhysicalWidth;
  FramebufferProperties.VirtualHeight := FramebufferProperties.PhysicalHeight * 2;
  FramebufferDeviceAllocate(FramebufferDevice, @FramebufferProperties);
  Sleep(500);


  FramebufferDeviceGetProperties(FramebufferDevice, @FramebufferProperties);
  BufferStart := Pointer(FramebufferProperties.Address);
  PageSize := FramebufferProperties.Pitch * FramebufferProperties.PhysicalHeight;
  CurrentPage := 0;

  FillChar(Pointer(BufferStart)^, PageSize * 2, 0); // clear the whole buffer

end;

function Emu_getMilliseconds() : longint; export; cdecl;
var
  difference : integer;
  now : ULONGLONG;
begin
  now := GetTickCount64();

  if (LastTick = 0) then
  begin
    LastTick := now;
  end;

  difference := now - LastTick;
  if (difference > 1000) then
  begin
    difference := difference - 1000;
    LastTick := now;
  end;

  Result := difference;
end;

var
  line : array[0..2048] of byte;

function  Emu_drawBuffer(pixels : pointer) : integer; export; cdecl;
var
  src : pointer;
  dst : pointer;
  i : integer;
  x, y : integer;

  OffsetX, OffsetY : integer;
begin
  Result := 0;

  //CurrentPage := (CurrentPage + 1) mod 2;  by not page flipping, we can overwrite the screen size with scaling and not suffer from a crash


  //scale by 2
  if (GfxWidth <= FramebufferProperties.PhysicalWidth * 2) then
  begin
    src := pixels;
    dst := BufferStart + (CurrentPage * PageSize);
    for y := 0 to GfxHeight - 1 do
    begin
      i := 0;
      for x := 0 to GfxWidth -1 do
      begin
        line[i] := pbyte(src)^;
        inc(i);
        line[i] := line[i-1];
        inc(i);
        inc(src);
      end;
      CopyMemory(dst, @line[0], GfxWidth * 2);
      dst := dst + FramebufferProperties.Pitch;
      CopyMemory(dst, @line[0], GfxWidth * 2);
      dst := dst + FramebufferProperties.Pitch;
    end;
  end else
  begin
    src := pixels;
    dst := BufferStart + (CurrentPage * PageSize);
    for y := 0 to GfxHeight - 1 do
    begin
      CopyMemory(dst, src, GfxWidth);
      dst := dst + FramebufferProperties.Pitch;
      src := src + GfxWidth;
    end;
  end;


  if (FramebufferProperties.Flags and FRAMEBUFFER_FLAG_CACHED) <> 0 then
  begin
    CleanDataCacheRange(PtrUInt(BufferStart) + (CurrentPage * PageSize), PageSize);
  end;

  OffsetX := 0;
  OffsetY := CurrentPage * FramebufferProperties.PhysicalHeight;
  FramebufferDeviceSetOffset(FramebufferDevice, OffsetX, OffsetY, True);

  if (FramebufferProperties.Flags and FRAMEBUFFER_FLAG_SYNC) <> 0 then
  begin
    FramebufferDeviceWaitSync(FramebufferDevice);
  end;
end;

function  Emu_enterGraphicsMode(width, height, bpp : integer) : integer; export; cdecl;
begin
  Result := 0;
  GfxWidth := width;
  GfxHeight := height;

  {$IFDEF PLATFORM_QEMU}
  writeln('GFX: ', GfxWidth, ' x ', GfxHeight, ' @ ', bpp);
  readln;
  {$ENDIF}

  FramebufferDevice := FramebufferDeviceGetDefault;
  FramebufferDeviceGetProperties(FramebufferDevice, @FramebufferProperties);
  FramebufferDeviceRelease(FramebufferDevice);
  Sleep(500);
  FramebufferProperties.Depth := 8;

  FramebufferProperties.VirtualWidth:= FramebufferProperties.PhysicalWidth;
  FramebufferProperties.VirtualHeight := FramebufferProperties.PhysicalHeight*2;

  FRAMEBUFFER_CONSOLE_AUTOCREATE := False;
  FramebufferDeviceAllocate(FramebufferDevice, @FramebufferProperties);
  Sleep(500);
  FramebufferDeviceSetPalette(FramebufferDevice, @VGAPalette);

  FramebufferDeviceGetProperties(FramebufferDevice, @FramebufferProperties);
  BufferStart := Pointer(FramebufferProperties.Address);
  PageSize := FramebufferProperties.Pitch * FramebufferProperties.PhysicalHeight;
  CurrentPage := 0;

  FillChar(Pointer(BufferStart)^, PageSize * 2, 0); // clear the whole buffer
end;

function  Emu_init() : integer; export; cdecl;
begin
  Result := 0;
  LastTick := 0;
  inANSI := False;
  inCSI := False;
end;

function  Emu_quit() : integer; export; cdecl;
begin
  WriteLn('Powering down...');
  SystemShutdown(0);
  Result := 0;
end;

function  Emu_open(filename : pchar; flags : integer) : integer; export; cdecl;
begin
  Result := -1;

  if (filename = 'bios') then begin Bios := TFileStream.Create('c:\bios', fmOpenRead); result := BIOS_HANDLE; end;
  if (filename = 'fd.img') then begin Floppy := TFileStream.Create('c:\fd.img', fmOpenReadWrite); result := FLOPPY_HANDLE; end;
end;

function  Emu_seek(handle, offset, whence : integer) : integer; export; cdecl;
var
  origin : TSeekOrigin;
begin
  Result := 0;

  if (whence = 0) then origin := TSeekOrigin.soBeginning;
  if (whence = 1) then origin := TSeekOrigin.soCurrent;
  if (whence = 2) then origin := TSeekOrigin.soEnd;

  if (handle = BIOS_HANDLE) then begin Bios.Seek(offset, origin); result := Bios.Position; end;
  if (handle = FLOPPY_HANDLE) then begin Floppy.Seek(offset, origin); result := Floppy.Position; end;
end;

function  Emu_read(handle : integer; buffer : pointer; amount : integer) : integer; export; cdecl;
var
  i : integer;
  r : integer;
begin
  Result := 0;

  if (handle = STD_IN) then
  begin
    if ConsoleKeypressed then
    begin
      pchar(buffer)^ := ConsoleReadKey;
      result := 1;
    end;
  end;

  if (handle = BIOS_HANDLE) then result := Bios.Read(buffer^, amount);
  if (handle = FLOPPY_HANDLE) then result := Floppy.Read(buffer^, amount);
end;

function  Emu_write(handle : integer; var buffer : pointer; amount : integer) : integer; export; cdecl;
var
  o : string;
begin
  Result := 0;

  writeln('WRITE', handle);
//  if (handle = FLOPPY_HANDLE) then begin Floppy.Write(buffer, amount); Result := amount; end;
end;

function Emu_keyEvent(var keyDown : integer; var keyValue : integer; var keyAlt : integer; var keyShift : integer; var keyCtrl : integer) : integer; export; cdecl;
begin
  Result := 0;
  if ConsoleKeypressed then
  begin
    keyDown := 1;
    keyValue := ord(ConsoleReadKey);
    result := 1;
  end;
end;


begin
  ThreadSetCPU(ThreadGetCurrent, CPU_ID_3);

  Sleep(100);
  WindowHandle := ConsoleWindowCreate(ConsoleDeviceGetDefault, CONSOLE_POSITION_FULLSCREEN, True);
  ConsoleWindowSetFont(WindowHandle,FontFindByName('Fixedsys_16'));
  ConsoleWindowSetCursorBlink(WindowHandle, True);
  ConsoleWindowSetBackcolor(WindowHandle, $FF000000);
  ConsoleWindowSetForecolor(WindowHandle, $FFFFBF00);

  while not DirectoryExists('C:\') do
  begin
    ConsoleWindowWrite(WindowHandle, '.');
    Sleep(100);
  end;
  ConsoleWindowClear(WindowHandle);

{$IFNDEF PLATFORM_QEMU}
  if UpdateKernel(True) then exit;
{$ENDIF}

  ConsoleWindowClear(WindowHandle);

  try
    LOOP('bios', 'fd.img', 'disk.img', 1);
  except
    on E:exception do
    begin
      ConsoleWriteLn(E.Message);
    end;
  end;
end. // DON'T FORGET TO COMPILE lib8086tiny.a

