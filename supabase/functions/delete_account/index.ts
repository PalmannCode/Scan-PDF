import {
  errorResponse,
  json,
  preflight,
  requireUser,
} from "../_shared/http.ts";

const buckets = [
  "scanned-documents",
  "original-pages",
  "processed-pages",
  "thumbnails",
  "exports",
  "signatures",
  "support-attachments",
];

async function listFiles(
  admin: Awaited<ReturnType<typeof requireUser>>["admin"],
  bucket: string,
  prefix: string,
): Promise<string[]> {
  const files: string[] = [];
  let offset = 0;
  while (true) {
    const { data, error } = await admin.storage.from(bucket).list(prefix, {
      limit: 1000,
      offset,
    });
    if (error) throw error;
    for (const item of data ?? []) {
      const path = `${prefix}/${item.name}`;
      if (item.id == null) files.push(...await listFiles(admin, bucket, path));
      else files.push(path);
    }
    if ((data?.length ?? 0) < 1000) break;
    offset += 1000;
  }
  return files;
}

Deno.serve(async (req) => {
  const options = preflight(req);
  if (options) return options;
  try {
    const { user, admin } = await requireUser(req);
    for (const bucket of buckets) {
      const paths = await listFiles(admin, bucket, user.id);
      for (let index = 0; index < paths.length; index += 100) {
        const { error } = await admin.storage
          .from(bucket)
          .remove(paths.slice(index, index + 100));
        if (error) throw error;
      }
    }
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) throw error;
    return json({ deleted: true });
  } catch (error) {
    return errorResponse(error);
  }
});
