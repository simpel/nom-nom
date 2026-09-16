import { createClient } from '@/utils/supabase/server'
import AdminNavbar from '@/components/admin/AdminNavbar'

export const dynamic = 'force-dynamic';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  return (
    <>
      <AdminNavbar email={user?.email ?? null} />
      {children}
    </>
  );
}
