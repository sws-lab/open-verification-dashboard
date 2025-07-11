import { z } from 'zod/v4';

const fileSchema = z.file();
fileSchema.mime(['application/zip', 'application/x-tar', 'application/gzip']);
fileSchema.max(1024 * 1024 * 1024); // 1 GB max file size


export const newProjectSchema = z.object({
  name: z.string().refine((val) => val.length > 0 && val.length <= 255, {
    error: 'Project name must be between 1 and 255 characters long.'
  }),
  description: z.optional(z.string().refine((val) => val.length <= 1000, {
    error: 'Description must be 1000 characters or less.'
  })),
  sources: fileSchema
})
