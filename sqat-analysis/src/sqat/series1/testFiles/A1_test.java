package nl.tudelft.jpacman.board;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.*;

import com.google.common.collect.ImmutableList;

import nl.tudelft.jpacman.sprite.Sprite;

/**
 * A square on a {@link Board}, which can (or cannot, depending on the type) be
 * occupied by units.
 * 
 * @author Jeroen Roosen 
 */
public abstract class Square {

	/**
	 * The units occupying this square, in order of appearance.
	 */
	private final List<Unit> occupants;
	private final int theAnswer = 42;
	private volatile static Integer ridiculouslyLongVariableNameThatAnySanePersonWouldHate = 43;
	/**
	 * Verifies that all occupants on this square have indeed listed this square
	 * as the square they are currently occupying.
	 * 
	 * @return <code>true</code> iff all occupants of this square have this
	 *         square listed as the square they are currently occupying.
	 */
	protected final boolean invariant() 
	{
		for (Unit occupant : occupants) {
			if (occupant.getSquare() != this) {
				return false;
			}
		}
		return true;
	}

	/**
	 * Determines whether the unit is allowed to occupy this square.
	 * 
	 * @param unit
	 *            The unit to grant or deny access.
	 * @return <code>true</code> iff the unit is allowed to occupy this square.
	 */
	public abstract boolean isAccessibleTo(Unit unit);

	/**
	 * Returns the sprite of this square.
	 * 
	 * @return The sprite of this square.
	 */
	public abstract Sprite getSprite();

}