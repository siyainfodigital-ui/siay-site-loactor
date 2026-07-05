export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      customers: {
        Row: {
          id: string
          customer_id: string | null
          consumer_no: string | null
          name: string
          mobile: string
          village: string | null
          taluka: string | null
          address: string | null
          solar_kw: number | null
          lat: number | null
          lng: number | null
          photo_url: string | null
          status: string
          installer: string | null
          created_at: string | null
          sync_status: string
          local_photo_path: string | null
        }
      }
      installations: {
        Row: {
          id: string
          customer_id: string
          structure_photo_url: string | null
          panel_photo_url: Json | null
          inverter_photo_url: string | null
          meter_photo_url: string | null
          final_photo_url: string | null
          geo_photo_url: string | null
          lat: number | null
          lng: number | null
          inverter_brand: string | null
          inverter_serial: string | null
          panel_brand: string | null
          panel_count: number | null
          panel_serials: Json | null
          generation_meter_no: string | null
          structure_photo_status: string | null
          panel_photo_status: string | null
          inverter_photo_status: string | null
          meter_photo_status: string | null
          final_photo_status: string | null
          admin_verified_photo_url: string | null
          verification_status: string | null
          admin_remark: string | null
          submitted_at: string | null
          verified_at: string | null
        }
      }
      logs: {
        Row: {
          id: string
          type: string
          message: string
          details: Json | null
          timestamp: string
          user_id: string | null
        }
      }
    }
  }
}
