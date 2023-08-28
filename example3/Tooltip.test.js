import React from 'react';
import { render } from '@testing-library/react';
import Tooltip from './';

test('displays tooltip with content correctly', () => {
  const wrapper = render(<Tooltip>test message</Tooltip>);

  const tooltip = wrapper.getByRole('tooltip');
  expect(tooltip).toHaveTextContent('test message');

  expect(tooltip).toHaveClass('maxio-tooltip--small');
});

test('displays tooltip with no .maxio-tooltip--small class if small=false props passed', () => {
  const wrapper = render(<Tooltip small={false}>test message</Tooltip>);

  const tooltip = wrapper.getByRole('tooltip');
  expect(tooltip).toHaveTextContent('test message');

  expect(tooltip).not.toHaveClass('maxio-tooltip--small');
});

test('displays tooltip with proper class if position passed', () => {
  const wrapper = render(<Tooltip arrowPosition={'top'}>test message</Tooltip>);

  const tooltip = wrapper.getByRole('tooltip');
  expect(tooltip).toHaveTextContent('test message');

  expect(tooltip).toHaveClass('maxio-tooltip--small maxio-tooltip--arrow-top');
});
