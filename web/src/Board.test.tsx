import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Board } from './Board'

const GRID = [
  [2, 0, 0, 0],
  [0, 4, 0, 0],
  [0, 0, 0, 0],
  [0, 0, 0, 8],
]

describe('Board', () => {
  it('renders one cell per grid position', () => {
    render(<Board grid={GRID} />)

    expect(screen.getAllByRole('gridcell')).toHaveLength(16)
  })

  it('shows the value of a tile', () => {
    render(<Board grid={GRID} />)

    expect(screen.getByText('8')).toBeInTheDocument()
  })

  it('leaves an empty cell blank', () => {
    render(<Board grid={GRID} />)

    expect(screen.getAllByRole('gridcell')[1]).toBeEmptyDOMElement()
  })
})
