import { getAdminUser } from '@/utils/supabase/admin-auth'
import AdminNavbar from '@/components/admin/AdminNavbar'

export const dynamic = 'force-dynamic';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // The navbar is for admins only. Access itself is enforced by every page,
  // route handler and server action (a layout does not protect its children).
  const user = await getAdminUser()

  return (
    <>
      {user && <AdminNavbar email={user.email ?? null} />}
      {children}
    </>
  );
}
