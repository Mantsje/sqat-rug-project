import java.util.ArrayList;

public abstract class Test {

	private final ArrayList<boolean> booleans;

	protected Test() {
		this.booleans = new ArrayList<>();
		for (int i = 0; i < 10; i++) {
			this.booleans[i] = (i % 2 == 0);
		}
	} // so cc = 2

	public int testMethod1() {								// 1
		int x = 0;
		for (int i = 0; i < 8; i++) {						// +1
			if (true) {										// +1
				if (true) {									// +1
					if (this.booleans.isEmpty()) {			// +1
						x = i;						
					}
				}
				if (false && !this.booleans.isEmpty()) {		// +2
					x = -i;
				}
			} else {
				x = 9;
			}
		}
		return x;
	} // so cc = 7
	
	public int testMethod2() {								// 1
		int x = 0;
		if ((1 == 2 && true) && this.booleans.isEmpty()) {	// +3
			if (true) {										// +1
				if (this.booleans.isEmpty()) {				// +1
					x = i;						
				}
			}
			if (false && !this.booleans.isEmpty()) {			// +2
				x = -i;
			}
		} else {
			x = 9;
		}
		return x;
	} // so cc = 8
	
	public int testMethod3() {								// 1
		int x = 0;
		if (true) {											// +1
			if (1 == 2 && true && this.booleans.isEmpty()) {	// +3
				x = i;						
			}
			if (false && !this.booleans.isEmpty()) {			// +2
				x = -i;
			}
		} else {
			x = 9;
		}
		return x;
	} // so cc = 7
	
	public void testMethod4() {								// 1
		int x = 0;
		if (1 == 2 && (true && this.booleans.isEmpty())) {	// +3
			if (true) {										// +1
				if (this.booleans.isEmpty()) {				// +1
					x = i;
				}
			}
			if (false && !this.booleans.isEmpty()) {			// +2
				x = -i;
			}
		} else {
			x = 9;
		}
	} // so cc = 8

	public int testMethod5() {						// 1
		int x = 0;
		for (int i = 0; i < 8; i++) {				// +1
			if (true) {								// +1
				if (false) {							// +1
					if (!this.booleans.isEmpty()) {	// +1
						x = -i;						
					}
				}
			} else {
				x = 9;
			}
		}
		return x;
	} // so cc = 5

	public int testMethod6() {	// 1
		int x = 0;
		if (true) {				// +1
			x = 1;
			if (false) {			// +1
				x = 2;
			}
			x = 3;
		} else {
			x = 4;
		}
		return x;
	} // so cc = 3

	public int testMethod7() {
		int x = 0;
		if (false && true) {		// +2
			x = 1;
		} else {
			x = 2;
		}
		return x;
	} // so cc = 3

	public int testMethod8() {	// 1
		int x = 0;
		if (false) {				// +1
			if (true) {			// +1
				x = 1;
			}
			x = 2;
		} else {
			x = 3;
		}
		if (x == 9) {			// +1
			x = 4;
		}
		return x;
	} // so cc = 4
	
	public int testMethod9() { // 1
		int x = 0;
		return x;
	} // so cc = 1

	public int testMethod10() {	// 1
		int i,n,j,x = 0;
		n = 4;
		while (i<n-1) {			// +1
			j = i + 1;
			while (j<n) {		// +1
				if (i<j) {		// +1
					swap(i, j);
				}
			}
			i=i+1;
		}
	} // so cc = 4
	
	public int testMethod11() {							// 1
		int x = 0;
		for (int i = 0; i < 8; i++) {					// +1
			if (true) {									// +1
				if (false && !this.booleans.isEmpty()) {	// +2
					x = -i;
				}
			} else {
				x = 9;
			}
		}
		return x;
	} // so cc = 5

}
