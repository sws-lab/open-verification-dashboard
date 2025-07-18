import { z } from 'zod/v4';

export const GET = z
	.object({
		filter: z.string().max(40),
		page: z.number().int().positive()
	})
	.strict();

export const POST = z
	.object({
		name: z.string().min(3).max(40),
		description: z.string().max(1000).optional(),
		projectId: z.number().int().positive()
	})
	.strict();

export const DELETE = z
	.object({
		projectId: z.number().int().positive()
	})
	.strict();
