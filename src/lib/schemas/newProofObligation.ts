import { z } from 'zod/v4';

const fileSchema = z.file();
fileSchema.mime('application/json');
fileSchema.max(10 * 1024 * 1024); // 10 MB max file size

export const newProofObligationSchema = z.object({
	name: z.string().min(3).max(100),
	proofObligation: fileSchema
})