use anchor_lang::prelude::*;

declare_id!("G6KM6e5pdAQwpft2ZcSGDxJxv92KYrVPTeak1JkfdVnx");

#[program]
pub mod guess_number {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
