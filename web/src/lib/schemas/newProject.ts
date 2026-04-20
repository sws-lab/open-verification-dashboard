import { z } from 'zod/v4';

const fileSchema = z.file();
fileSchema.mime(['application/zip', 'application/x-tar', 'application/gzip']);
fileSchema.max(1024 * 1024 * 1024); // 1 GB max file size

export const newProjectSchema = z.object({
	name: z.string().min(3).max(100),
	description: z.optional(z.string().max(1000)),
	sources: fileSchema
});
