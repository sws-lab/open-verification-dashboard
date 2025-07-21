import { z } from 'zod/v4';

export const editProjectSchema = z.object({
	name: z.string().min(3).max(100),
	description: z.optional(z.string().max(1000))
});
