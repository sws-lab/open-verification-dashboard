import { z } from 'zod/v4';

const fileSchema = z.file();
fileSchema.mime(['application/zip', 'application/x-tar', 'application/gzip']);
fileSchema.max(1024 * 1024 * 1024); // 1 GB max file size

export const newRevisionSchema = z.object({
	id: z.int().nonnegative(),
	revision: z.int().nonnegative(),
	sources: fileSchema
});
