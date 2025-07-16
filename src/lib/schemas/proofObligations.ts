import {z} from 'zod/v4';

export const GET = z.object({
	filter: z.string().max(100).optional(),
	page: z.number().int().positive().default(1),
	projectId: z.number().int().positive(),
	revision: z.number().int().positive()
}).strict();

const range = z.object({
	file: z.string().max(200).optional(),
	line: z.number().int().nonnegative().optional(),
	column: z.number().int().nonnegative().optional()
});

const check = z.object({
	kind: z.enum(['safe', 'warning', 'error']),
	title: z.string().max(100),
	messages: z.string().max(1000),
	range: z.object({
		start: range,
		end: range
	})
});


export const ProofObligationSchema = z.object({
	time: z.number(),
	checks: z.array(check),
});
