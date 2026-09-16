'use client'

import { toast } from 'sonner'
import { generateRecipeHealthScoreAction } from '@/app/admin/actions'

export default function GenerateHealthScoreButton({ recipeId }: { recipeId: string }) {
  const handleClick = () => {
    toast.promise(
      generateRecipeHealthScoreAction(recipeId),
      {
        loading: 'Generating health score...',
        success: 'Health score updated',
        error: (err) => `Failed to generate health score: ${err.message}`
      }
    )
  }

  return (
    <button
      onClick={handleClick}
      className="px-4 py-2 bg-black text-white rounded-md hover:bg-gray-800 text-sm font-medium whitespace-nowrap"
    >
      Generate Health Score
    </button>
  )
}
