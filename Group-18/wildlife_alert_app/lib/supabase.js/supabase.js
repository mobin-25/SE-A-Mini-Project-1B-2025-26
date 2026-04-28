import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://ghgurilvhvyjfjdaqhzx.supabase.co'
const supabaseAnonKey ='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoZ3VyaWx2aHZ5amZqZGFxaHp4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0NDEzNDksImV4cCI6MjA5MTAxNzM0OX0.ukkMoEeUolHzKJ7vs1Q6n1jd4WJpFpiVeSA67KTioUc'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)