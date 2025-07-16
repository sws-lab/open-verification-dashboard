import {z} from 'zod/v4';

export const GET = z.object({
	proofObligationId1: z.number().int().nonnegative(),
	proofObligationId2: z.number().int().nonnegative(),
})