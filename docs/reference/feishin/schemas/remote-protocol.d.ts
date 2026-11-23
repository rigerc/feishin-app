/**
 * Unofficial standalone Feishin Remote WebSocket API declarations.
 * Based on src/shared/types/remote-types.ts (development branch), 2026-11-23.
 * This is a convenience re-expression, NOT an exact copy of upstream sources.
 * QueueSong is deliberately open-ended; consult domain-types.ts for full Song fields.
 */
export type Play = 'index' | 'last' | 'lastShuffle' | 'next' | 'nextShuffle' | 'now' | 'shuffle';
export type PlayerRepeat = 'all' | 'none' | 'one';
export type PlayerStatus = 'paused' | 'playing' | 'stopped';
export type QueueSong = { id: string; _uniqueId: string; _contextPlaylistId?: string | null; [key: string]: unknown };
export type SongState = {
  position?: number; repeat?: PlayerRepeat; shuffle?: boolean;
  song?: QueueSong; status?: PlayerStatus; volume?: number;
};
export type RemoteListRequest = {requestId: string; limit?: number; searchTerm?: string; startIndex?: number};
export type RemoteTrackItem = {album: string | null; artistName: string; duration: number; id: string; imageUrl: string | null; name: string};
export type RemoteAlbumItem = {albumArtistName: string; duration: number | null; id: string; imageUrl: string | null; name: string; releaseYear: number | null; songCount: number | null};
export type RemotePlaylistItem = {duration: number | null; id: string; imageUrl: string | null; name: string; songCount: number | null};
export type RemoteRadioItem = {homepageUrl: string | null; id: string; imageUrl: string | null; name: string};
export type RemoteQueueItem = {album: string | null; artistName: string; duration: number; id: string; imageUrl: string | null; name: string; uniqueId: string};
export type SimpleClientEvent = {event: 'play'|'pause'|'next'|'previous'|'shuffle'|'repeat'|'proxy'};
export type AckableClientEvent =
  | {event:'add-to-playlist'; playlistId:string; songId:string; requestId?:string}
  | {event:'clear-queue'; requestId?:string}
  | {event:'play-album'|'play-playlist'|'play-track'; id:string; playType?:Play; requestId?:string}
  | {event:'play-track-radio'; id:string; playType:Play; requestId?:string};
export type ClientEvent =
  | SimpleClientEvent
  | AckableClientEvent
  | {event:'authenticate'; header:string}
  | {event:'favorite'; id:string; favorite:boolean}
  | {event:'rating'; id:string; rating:number}
  | {event:'play-radio'; id:string}
  | {event:'position'; position:number}
  | {event:'volume'; volume:number}
  | {event:'queue-jump'|'remove-from-queue'; uniqueId:string}
  | {event:'reorder-queue'; edge:'bottom'|'top'; targetUniqueId:string; uniqueId:string}
  | ({event:'tracks-request'|'albums-request'|'playlists-request'|'radio-request'} & RemoteListRequest);
export type ServerEvent =
  | {event:'accent-color'; data:{dark:string;light:string}}
  | {event:'confirm-queue-changes-setting'; data:boolean}
  | {event:'error'; data:string}
  | {event:'favorite'; data:{id:string; favorite:boolean}}
  | {event:'rating'; data:{id:string; rating:number}}
  | {event:'operation-ack'; data:{requestId:string; error?:string}}
  | {event:'playback'; data:PlayerStatus}
  | {event:'position'; data:number}
  | {event:'proxy'; data:string}
  | {event:'queue-state'; data:{currentUniqueId:string|null;items:RemoteQueueItem[]}}
  | {event:'radio-status'; data:{isActive:true;imageUrl:string|null;stationName:string}|{isActive:false}}
  | {event:'repeat'; data:PlayerRepeat}
  | {event:'shuffle'; data:boolean}
  | {event:'song'; data:QueueSong|null}
  | {event:'state'; data:SongState}
  | {event:'volume'; data:number}
  | {event:'tracks-response'; data:{hasMore:boolean;items:RemoteTrackItem[];requestId:string}}
  | {event:'albums-response'; data:{hasMore:boolean;items:RemoteAlbumItem[];requestId:string}}
  | {event:'playlists-response'; data:{hasMore:boolean;items:RemotePlaylistItem[];requestId:string}}
  | {event:'radio-response'; data:{hasMore:boolean;items:RemoteRadioItem[];requestId:string}};
/** The source also defines SongUpdateSocket, which is not itself a wire event. */
export type SongUpdateSocket = Omit<SongState,'song'> & {position?:number;song?:QueueSong|null};
