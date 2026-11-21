interface BoardProps {
  grid: number[][]
}

export function Board({ grid }: BoardProps) {
  return (
    <div className="board" role="grid" aria-label="2048 board">
      {grid.map((row, rowIndex) => (
        <div className="board-row" role="row" key={rowIndex}>
          {row.map((value, colIndex) => (
            <div className="tile" role="gridcell" key={colIndex}>
              {value === 0 ? '' : value}
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}
