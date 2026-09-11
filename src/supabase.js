import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL || 'https://mhhogqovmhiuuihqowta.supabase.co';
const key =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY ||
  import.meta.env.VITE_SUPABASE_ANON_KEY ||
  '';

export const supabase = url && key ? createClient(url, key) : null;
export const supabaseConfigError = !supabase
  ? 'Supabase is not configured. Add VITE_SUPABASE_PUBLISHABLE_KEY in your deployment environment.'
  : '';
