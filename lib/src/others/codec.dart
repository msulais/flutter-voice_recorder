import 'package:flutter_sound/flutter_sound.dart' show Codec;

String codecToString(Codec codec){
  switch (codec){
    case Codec.defaultCodec: break;
    case Codec.aacADTS   : return 'AAC/ADTS'   ;
    case Codec.opusOGG   : return 'Opus/OGG'   ;
    case Codec.opusCAF   : return 'Opus/CAF'   ;
    case Codec.mp3       : return 'MP3'        ;
    case Codec.vorbisOGG : return 'Vorbis/OGG' ;
    case Codec.pcm16     : return 'PCM16'      ;
    case Codec.pcm16WAV  : return 'PCM16/WAV'  ;
    case Codec.pcm16AIFF : return 'PCM16/AIFF' ;
    case Codec.pcm16CAF  : return 'PCM16/CAF'  ;
    case Codec.flac      : return 'FLAC'       ;
    case Codec.aacMP4    : return 'AAC/MP4'    ;
    case Codec.amrNB     : return 'AMR-NB'     ;
    case Codec.amrWB     : return 'AMR-WB'     ;
    case Codec.pcm8      : return 'PCM8'       ;
    case Codec.pcmFloat32: return 'PCM Float32';
    case Codec.pcmWebM   : return 'PCM/WebM'   ;
    case Codec.opusWebM  : return 'Opus/WebM'  ;
    case Codec.vorbisWebM: return 'Vorbis/WebM';
  }

  return '';
}